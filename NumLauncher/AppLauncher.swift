//
//  AppLauncher.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/8/26.
//

import AppKit

@MainActor
final class AppLauncher {
    
    init() {}
    
    /// Looks up a shortcut slot by its index within the provided settings and safely launches the associated application.
    /// - Parameters:
    ///   - index: The triggered shortcut slot index.
    ///   - settings: The app's configuration state containing the registered shortcuts.
    func launchApplication(for index: Int, settings: AppSettings) async -> Bool {
        // Find the slot matching the triggered index
        guard let slot = settings.shortcutSettings.first(where: { $0.index == index }),
              let url = slot.appURL else {
            debugPrint("[AppLauncher] No application configured for slot index: \(index)")
            return false
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error = error {
                    debugPrint("[AppLauncher] Failed to launch app at \(url.path): \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else {
                    debugPrint("[AppLauncher] Successfully launched: \(url.lastPathComponent)")
                    continuation.resume(returning: true)
                }
            }
        }
    }
}
