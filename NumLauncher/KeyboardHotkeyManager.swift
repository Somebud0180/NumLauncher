//
//  KeyboardHotkeyManager.swift
//  NumLauncher
//
//  Created by Assistant on 7/8/26.
//
//  Adapted from ConType

import AppKit
import ApplicationServices

/// Represents a registered keyboard shortcut with its associated slot index.
private struct RegisteredShortcut: Equatable {
    let index: Int
    let key: String
    let modifiers: NSEvent.ModifierFlags

    var displayText: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("Ctrl") }
        if modifiers.contains(.option) { parts.append("Option") }
        if modifiers.contains(.command) { parts.append("Command") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        switch key {
        case " ": parts.append("Space")
        case "\r": parts.append("Return")
        default: parts.append(key.uppercased())
        }
        return parts.joined(separator: " + ")
    }
}

/// KeyboardHotkeyManager monitors global keyboard events and triggers callbacks for matching shortcuts.
/// - Note: Requires Input Monitoring/Accessibility permission to install a global event tap.
@MainActor
final class KeyboardHotkeyManager {
    /// Called when a registered shortcut is triggered. Provides the associated index.
    var onTrigger: ((Int) -> Void)?
    
    /// Dynamic check to determine if hotkeys should step aside for Spotlight.
    var shouldDisableInSpotlight: (() -> Bool)?
    
    /// Current set of registered shortcuts.
    private var shortcuts: [RegisteredShortcut] = []

    /// Event tap & run loop source.
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    deinit {
        // Avoid calling @MainActor-isolated methods from deinit. Ensure `stop()` is called explicitly by the owner when appropriate.
    }

    /// Replaces the current shortcuts with the given list.
    /// - Parameter shortcuts: Array of tuples describing index, key, and modifiers.
    func configure(shortcuts: [(index: Int, key: String, modifiers: NSEvent.ModifierFlags)]) {
        self.shortcuts = shortcuts.map { RegisteredShortcut(index: $0.index, key: $0.key, modifiers: $0.modifiers.intersection(.deviceIndependentFlagsMask)) }
    }

    /// Starts monitoring for registered shortcuts. Optionally requests permission if needed.
    func start(requestPermissionIfNeeded: Bool = true) {
        stop()

        // Check Accessibility/Input Monitoring permission
        if !InputMonitoringPermission.isAuthorized() {
            if requestPermissionIfNeeded {
                _ = InputMonitoringPermission.requestAuthorization()
            }
            // Re-check after request; user may need to restart app, so don't proceed if still unauthorized
            guard InputMonitoringPermission.isAuthorized() else {
                debugPrint("[KeyboardHotkeyManager] Not authorized for Input Monitoring. Hotkeys disabled.")
                return
            }
        }

        guard installEventTap() else {
            debugPrint("[KeyboardHotkeyManager] Failed to create event tap. Hotkeys disabled.")
            stop()
            return
        }
    }

    /// Stops monitoring and tears down event tap resources.
    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }

    /// Installs a global event tap to monitor keyDown events.
    private func installEventTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: KeyboardHotkeyManager.eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
        return true
    }

    /// Matches an NSEvent against registered shortcuts.
    private func matchingIndex(for event: NSEvent) -> Int? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let key = eventKey(from: event) else { return nil }
        return shortcuts.first(where: { $0.modifiers == flags && $0.key == key })?.index
    }

    /// Normalizes an NSEvent into a numeric key string ("0"..."9") using hardware keycodes.
    private func eventKey(from event: NSEvent) -> String? {
        switch event.keyCode {
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
            // Numpad Support
        case 83: return "1"
        case 84: return "2"
        case 85: return "3"
        case 86: return "4"
        case 87: return "5"
        case 88: return "6"
        case 89: return "7"
        case 91: return "8"
        case 92: return "9"
        case 82: return "0"
        default:
            return nil
        }
    }

    /// C callback bridging to instance method.
    private static let eventTapCallback: CGEventTapCallBack = { _, type, cgEvent, refcon in
        guard type == .keyDown, let refcon = refcon else {
            return Unmanaged.passUnretained(cgEvent)
        }
        
        let manager = Unmanaged<KeyboardHotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
        guard let nsEvent = NSEvent(cgEvent: cgEvent) else {
            return Unmanaged.passUnretained(cgEvent)
        }
        
        let checkSpotlight = manager.shouldDisableInSpotlight?() ?? false
        
        if checkSpotlight {
            let isSpotlightOpen = manager.isSpotlightActive() || manager.isSpotlightWindowVisible()
            if isSpotlightOpen {
                let flags = nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if flags == .command {
                    if let keyStr = manager.eventKey(from: nsEvent),
                       let targetNumber = Int(keyStr), (1...4).contains(targetNumber) {
                        // Let Spotlight handle Cmd + 1 to 4 natively by passing the event through
                        return Unmanaged.passUnretained(cgEvent)
                    }
                }
            }
        }
        
        if let index = manager.matchingIndex(for: nsEvent) {
            DispatchQueue.main.async {
                manager.onTrigger?(index)
            }
            // Swallow the event so the front app doesn't also handle it
            return nil
        }
        
        return Unmanaged.passUnretained(cgEvent)
    }
    
    func isSpotlightActive() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        return frontApp.bundleIdentifier == "com.apple.Spotlight" || frontApp.bundleIdentifier == "com.apple.Siri" || frontApp.bundleIdentifier == "com.apple.campo"
    }
    
    func isSpotlightWindowVisible() -> Bool {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               ownerName == "Spotlight" || ownerName == "Siri" {
                return true
            }
        }
        return false
    }
}
