//
//  SettingsView.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showSpotlightPopover = false
    private let shortcutKeys = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Image(systemName: "number.sign")
                            .resizable()
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .foregroundStyle(.red)
                            )
                            .frame(width: 96, height: 96)
                        
                        Text("NumLauncher")
                            .font(.largeTitle)
                        
                        Text("Configure the quick shortcuts and the rest of the app here.")
                    }
                }
                
                Section(header: Text("Genaral")) {
                    Toggle("Open app on startup", isOn: $settings.openAppOnStartup)
                    
                    Picker("App theme", selection: $settings.preferredColorScheme) {
                        ForEach(PreferredColorScheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    
                    VStack {
                        Toggle("Disable when spotlight is open", isOn: $settings.disableInSpotlight)
                            .help("On macOS 26 and newer, it uses the shortcut Command + 1 to 4 to access different sections of Spotlight. You can make the app temporarily ignore these when Spotlight is open.")
                        if #available(anyAppleOS 27.0, *), settings.disableInSpotlight {
                            Text("Due to limitations, the app will also temporarily disable shortcuts 1-4 when the Siri AI (Chat) app is open.")
                                .font(.footnote)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                
                Section(header: Text("Quick Shortcuts")) {
                    ForEach(shortcutKeys, id: \.self) { num in
                        shortcutConfig(for: binding(for: num))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("NumLauncher Settings")
        }
    }
    
    private func shortcutConfig(for shortcut: Binding<ShortcutSettings>) -> some View {
        HStack {
            // Read properties directly out of the wrapped value
            Image(systemName: shortcut.wrappedValue.modifier.imageSymbol)
            Image(systemName: "plus")
            Text("\(shortcut.wrappedValue.index)")
                .frame(width: 16, alignment: .leading)
            
            Spacer()
            
            // Pass the binding further into your button
            shortcutConfigButton(for: shortcut)
        }
        .font(.body)
    }
    
    private func shortcutConfigButton(for shortcut: Binding<ShortcutSettings>) -> some View {
        Button(action: {
            openFilePicker(for: shortcut)
        }, label: {
            HStack {
                if let appName = shortcut.wrappedValue.appName, shortcut.wrappedValue.appBundleIdentifier != nil {
                    shortcut.wrappedValue.appIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Text(appName)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        shortcut.wrappedValue.appBundleIdentifier = nil
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                } else {
                    Text("Choose App...")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .frame(maxWidth: 200, minHeight: 32, maxHeight: 32)
        })
        .buttonStyle(.bordered)
    }
    
    private func openFilePicker(for shortcut: Binding<ShortcutSettings>) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        
        if let appsFolderURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first {
            panel.directoryURL = appsFolderURL
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                shortcut.wrappedValue.appBundleIdentifier = bundleID
            }
        }
    }
    
    private func binding(for number: Int) -> Binding<ShortcutSettings> {
        Binding(
            get: {
                // If it exists in settings, return it.
                if let match = settings.shortcutSettings.first(where: { $0.index == number }) {
                    return match
                }
                // Otherwise, lazily provide a default Command layout
                return ShortcutSettings(modifier: .command, index: number, appBundleIdentifier: nil)
            },
            set: { newValue in
                // When modified, update the array inside AppSettings
                if let index = settings.shortcutSettings.firstIndex(where: { $0.index == number }) {
                    settings.shortcutSettings[index] = newValue
                } else {
                    settings.shortcutSettings.append(newValue)
                }
            }
        )
    }
}

#Preview {
    let appSettings = AppSettings()
    return SettingsView()
        .environmentObject(appSettings)
        .frame(maxWidth: 360, maxHeight: 900)
}
