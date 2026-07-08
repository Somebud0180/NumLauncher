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
    private lazy var settingsController = SettingsWindowController()
    private var cancellables = Set<AnyCancellable>()
    
    private let launchAtLoginService = SMAppService.mainApp
    private let hotkeyManager = KeyboardHotkeyManager()
    private let settings = AppSettings()
    private let appLauncher = AppLauncher()
    
    init() {
        configureOpenAppOnStartup()
        setupSettingsObservers()
        
        hotkeyManager.shouldDisableInSpotlight = { [weak self] in
            self?.settings.disableInSpotlight ?? false
        }
        
        hotkeyManager.onTrigger = { [weak self] index in
            guard let self = self else { return }
            self.appLauncher.launchApplication(for: index, settings: self.settings)
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
    
    /// Sets up observers for openAppOnStartup and shortcutSettings changes.
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
        let mapped: [(index: Int, key: String, modifiers: NSEvent.ModifierFlags)] = settings.shortcutSettings.compactMap { s in
            // Shift physical keys to match user interface bindings precisely (Visual key "1" maps to slot 1, up through key "0" mapping to slot 0/10)
            let key: String
            switch s.index {
            case 1: key = "1"
            case 2: key = "2"
            case 3: key = "3"
            case 4: key = "4"
            case 5: key = "5"
            case 6: key = "6"
            case 7: key = "7"
            case 8: key = "8"
            case 9: key = "9"
            case 0, 10: key = "0"
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
