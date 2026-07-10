//
//  AccessibilityPermission.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/10/26.
//

import ApplicationServices
import Foundation

/// Enum for managing Accessibility (AX) permissions on macOS.
public enum AccessibilityPermission {
    /// Test seam that can replace the real authorization check when needed.
    public static var isAuthorizedProvider: @MainActor () -> Bool = {
        return AXIsProcessTrusted()
    }
    
    /// Checks if the app is authorized for Accessibility.
    @MainActor
    public static func isAuthorized() -> Bool {
        return isAuthorizedProvider()
    }
    
    /// Requests Accessibility permissions by triggering the native system prompt.
    @MainActor
    public static func requestAuthorization() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
