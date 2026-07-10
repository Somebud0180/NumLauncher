//
//  SettingsWindowController.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?
    private var window: NSWindow?
    
    /// A computed property that checks if the settings window is currently visible by accessing the `isVisible` property of the window.
    var isVisible: Bool {
        window?.isVisible == true
    }
    
    /// Shows the settings window. If the window doesn't exist yet, it creates it using `makeWindowIfNeeded()`, then makes it key and orders it to the front.
    /// - Parameter settings: The shared configuration instance passed from the AppCoordinator.
    func show(with settings: AppSettings) {
        let window = makeWindowIfNeeded(with: settings)
        window.makeKeyAndOrderFront(nil)
    }
    
    /// Closes the settings window by calling `performClose(nil)`.
    func close() {
        window?.performClose(nil)
    }
    
    /// NSWindowDelegate method that gets called when the window is about to close.
    /// - Parameter notification: The notification object containing information about the window closing event.
    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
    
    /// Creates the settings window if it doesn't exist, sets up the hosting controller with the settings view and configures the window properties.
    /// - Parameter settings: The settings instance to inject into the view environment.
    /// - Returns: An `NSWindow` containing the settings view.
    private func makeWindowIfNeeded(with settings: AppSettings) -> NSWindow {
        if let window {
            return window
        }
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame
        
        let hostingController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(settings)
                .frame(minWidth: 440, maxWidth: 440, minHeight: 240, idealHeight: 520, maxHeight: 600)
        )
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.autoresizingMask = .height
        
        let origin = NSPoint(
            x: (frame?.midX ?? 960) - (440 / 2),
            y: (frame?.midY ?? 540) - (520 / 2)
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: origin.x, y: origin.y, width: 440, height: 520),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.title = "Settings"
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.managed, .moveToActiveSpace, .fullScreenNone, .participatesInCycle]
        
        self.window = window
        return window
    }
}
