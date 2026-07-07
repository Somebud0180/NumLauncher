//
//  AppCoordinator.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import AppKit
import SwiftUI
import ServiceManagement

@MainActor
final class AppCoordinator {
    private let launchAtLoginService = SMAppService.mainApp
    private lazy var settingsController = SettingsWindowController()
    
    @AppStorage("openAppOnStartup") private var openAppOnStartup = true
    
    init() {
        configureOpenAppOnStartup()
    }
    
    /// Opens the settings window and ensures the app is in regular activation mode so it can receive focus.
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        settingsController.show()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Quits the app.
    func quit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Launch at Login Configuration
    /// Updates the launch-at-login setting based on the current state of the system and user preferences, and sets up a listener to keep them in sync.
    private func configureOpenAppOnStartup() {
        openAppOnStartup = isLaunchAtLoginEnabled
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
        if openAppOnStartup != resolvedValue {
            openAppOnStartup = resolvedValue
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
