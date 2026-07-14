//
//  AppSettings.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/8/26.
//

import Foundation
import SwiftUI
import Combine

enum PreferredColorScheme: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .system: "System"
        case .dark: "Dark Mode"
        case .light: "Light Mode"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

enum Modifier: String, Codable, CaseIterable, Identifiable, Hashable {
    case command
    case option
    case control
    case shift
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .command:
            return "Command"
        case .option:
            return "Option"
        case .control:
            return "Control"
        case .shift:
            return "Shift"
        }
    }
    
    var imageSymbol: String {
        switch self {
        case .command:
            return "command"
        case .option:
            return "option"
        case .control:
            return "control"
        case .shift:
            return "shift.fill"
        }
    }
    
    var flag: NSEvent.ModifierFlags {
        switch self {
        case .command:
            return .command
        case .option:
            return .option
        case .control:
            return .control
        case .shift:
            return .shift
        }
    }
    
    static let displayOrder: [Modifier] = [.command, .option, .control, .shift]
}

struct ShortcutSettings: Codable, Identifiable, Equatable {
    var id = UUID()
    
    var modifiers: Set<Modifier>
    
    var index: Int
    
    var appNameStatic: String?
    
    var appBundleIdentifier: String?
    
    var modifierFlags: NSEvent.ModifierFlags {
        modifiers.reduce([]) { $0.union($1.flag) }
    }
    
    var appURL: URL? {
        guard let bundleID = appBundleIdentifier else { return nil }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }
    
    var appName: String? {
        // If we don't have a resolvable URL, fall back to the static name if provided
        guard let appURL = appURL else {
            return appNameStatic ?? "None"
        }
        
        // 1. Try to read the localized or standard display name from the app's resource values
        if let resourceValues = try? appURL.resourceValues(forKeys: [.localizedNameKey, .nameKey]) {
            if let localizedName = resourceValues.localizedName {
                return localizedName
            } else if let name = resourceValues.name {
                // Strips the ".app" extension out if it's appended
                return name.replacingOccurrences(of: ".app", with: "")
            }
        }
        
        // 2. Fallback: Extract the last path component from the URL itself (e.g., "Safari.app")
        let filename = appURL.lastPathComponent
        if filename.hasSuffix(".app") {
            return String(filename.dropLast(4))
        }
        
        // 3. Final fallback to static name if available, otherwise nil (or "None")
        return appNameStatic ?? (filename.isEmpty ? nil : filename)
    }
    
    var appIcon: Image {
        if let appURL = appURL {
            let nsImage = NSWorkspace.shared.icon(forFile: appURL.path)
            return Image(nsImage: nsImage)
        }
        
        return Image(systemName: "app.grid")
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var openAppOnStartup: Bool = true {
        didSet { queueSave() }
    }
    
    @Published var preferredColorScheme: PreferredColorScheme = .system {
        didSet { queueSave() }
    }
    
    @Published var disableInSpotlight: Bool = true {
        didSet { queueSave() }
    }
    
    @Published var preferredModifier: Set<Modifier> = [.command] {
        didSet { queueSave() }
    }
    
    @Published var shortcutSettings: [ShortcutSettings] = [] {
        didSet { queueSave() }
    }
    
    /// For testing and overrides
    static var settingsURLOverride: URL?
    
    private var saveTask: Task<Void, Never>?
    
    /// Minimal Codable structure used strictly for file persistence
    private struct PersistedData: Codable {
        let openAppOnStartup: Bool
        let preferredColorScheme: PreferredColorScheme
        let disableInSpotlight: Bool
        let preferredModifier: Set<Modifier>
        let shortcutSettings: [ShortcutSettings]
    }
    
    init() {
        load()
    }
    
    // MARK: - Persistence Paths
    
    private static var settingsURL: URL {
        if let override = settingsURLOverride {
            return override
        }
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NumLauncher", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("settings.json")
    }
    
    // MARK: - Save & Load
    
    /// Lightweight Task-based debounce to replace complex Combine streams
    private func queueSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    
    private func save() {
        let dataToSave = PersistedData(
            openAppOnStartup: openAppOnStartup,
            preferredColorScheme: preferredColorScheme,
            disableInSpotlight: disableInSpotlight,
            preferredModifier: preferredModifier,
            shortcutSettings: shortcutSettings
        )
        
        do {
            let data = try JSONEncoder().encode(dataToSave)
            try data.write(to: Self.settingsURL, options: .atomic)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: Self.settingsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: Self.settingsURL)
            let decoded = try JSONDecoder().decode(PersistedData.self, from: data)
            
            self.preferredColorScheme = decoded.preferredColorScheme
            self.disableInSpotlight = decoded.disableInSpotlight
            self.preferredModifier = decoded.preferredModifier
            self.shortcutSettings = decoded.shortcutSettings
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
}

