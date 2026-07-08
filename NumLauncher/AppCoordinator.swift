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
    private var cancellables = Set<AnyCancellable>()
    let settings = AppSettings()
    
    init() {
        configureOpenAppOnStartup()
        setupSettingsObservers()
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
