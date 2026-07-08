//
//  AppCoordinator.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import AppKit
import SwiftUI
import ServiceManagement
import Combine

@MainActor
final class AppCoordinator {
    private let launchAtLoginService = SMAppService.mainApp
    private lazy var settingsController = SettingsWindowController()
    private let hotkeyManager = KeyboardHotkeyManager()
    private var cancellables = Set<AnyCancellable>()
    let settings = AppSettings()
    
    init() {
        configureOpenAppOnStartup()
        setupSettingsObservers()
        
        hotkeyManager.onTrigger = { index in
            if let slot = self.settings.shortcutSettings.first(where: { $0.index == index }),
               let url = slot.appURL {
                NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
            }
        }
        
        applySettings()
        hotkeyManager.start(requestPermissionIfNeeded: true)
    }
    
    /// Opens the settings window and ensures the app is in regular activation mode so it can receive focus.
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        settingsController.show(with: settings)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Quits the app.
    func quit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Launch at Login Configuration
    /// Updates the launch-at-login setting based on the current state of the system and user preferences, and sets up a listener to keep them in sync.
    private func configureOpenAppOnStartup() {
        settings.openAppOnStartup = isLaunchAtLoginEnabled
    }
    
    /// Checks the current status of the launch-at-login service to determine if launch-at-login is effectively enabled.
    private var isLaunchAtLoginEnabled: Bool {
        switch launchAtLoginService.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Sets up observers for openAppOnStartup to allow the coordinator to update the service manager
    private func setupSettingsObservers() {
        settings.$openAppOnStartup
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] shouldEnable in
                guard let self = self else { return }
                Task { @MainActor in
                    self.setLaunchAtLoginEnabled(shouldEnable)
                }
            }
            .store(in: &cancellables)
        
        settings.$shortcutSettings
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.applySettings()
            }
            .store(in: &cancellables)
    }
    
    /// Enables or disables launch-at-login based on the provided boolean, and ensures the app's settings reflect the effective state of the launch-at-login service after the change.
    /// - Parameter shouldEnable: A boolean indicating whether launch-at-login should be enabled or disabled.
    private func setLaunchAtLoginEnabled(_ shouldEnable: Bool) {
        guard isLaunchAtLoginEnabled != shouldEnable else { return }
        
        do {
            if shouldEnable {
                try launchAtLoginService.register()
            } else {
                try launchAtLoginService.unregister()
            }
        } catch {
            debugPrint("[AppSettings] Failed to update launch-at-login setting:", error)
        }
        
        let resolvedValue = isLaunchAtLoginEnabled
        if settings.openAppOnStartup != resolvedValue {
            settings.openAppOnStartup = resolvedValue
        }
    }
    
    func applySettings() {
        // Map only indices 0-9 to numeric keys 1-0 and ignore others
        let mapped: [(index: Int, key: String, modifiers: NSEvent.ModifierFlags)] = settings.shortcutSettings.compactMap { s in
            guard (0...9).contains(s.index) else { return nil }

            let key: String
            switch s.index {
            case 0: key = "1"
            case 1: key = "2"
            case 2: key = "3"
            case 3: key = "4"
            case 4: key = "5"
            case 5: key = "6"
            case 6: key = "7"
            case 7: key = "8"
            case 8: key = "9"
            case 9: key = "0"
            default: return nil
            }

            let flags: NSEvent.ModifierFlags
            switch s.modifier {
            case .command: flags = [.command]
            case .option: flags = [.option]
            case .control: flags = [.control]
            }

            return (index: s.index, key: key, modifiers: flags)
        }

        hotkeyManager.configure(shortcuts: mapped)
    }
    
    @MainActor
    static func defaultRestartApplication() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
