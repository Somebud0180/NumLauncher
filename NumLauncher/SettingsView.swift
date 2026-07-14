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
    @State private var showSpotlightPopover: Bool = false
    @State private var isEditingModifiers: Bool = false
    private let shortcutKeys = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
    private let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Image("AppIcon")
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                        
                        Text("NumLauncher")
                            .font(.largeTitle)
                        
                        Text("Configure the quick shortcuts and the rest of the app here.")
                    }
                }
                
                Section(header: Text("Genaral")) {
                    Picker("App theme", selection: $settings.preferredColorScheme) {
                        ForEach(PreferredColorScheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    
                    Toggle("Open app on startup", isOn: $settings.openAppOnStartup)
                    
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
                    modifierConfig
                }
                
                Section {
                    ForEach(shortcutKeys, id: \.self) { num in
                        shortcutConfig(for: binding(for: num))
                    }
                }
                
                Section(footer: footer) {
                    HStack {
                        Text("Version")
                        
                        Spacer()
                        
                        Text("\(version) (\(build))")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(
                        destination: URL(string: "https://github.com/somebud0180/numlauncher")!,
                        label: {
                            Text("Source Code")
                            
                            Spacer()
                            
                            Text("GitHub \(Image(systemName: "chevron.right"))")
                                .foregroundStyle(.gray)
                        }
                    )
                }
            }
            .formStyle(.grouped)
            .navigationTitle("NumLauncher Settings")
        }
        .preferredColorScheme(settings.preferredColorScheme.colorScheme)
    }
    
    var footer: some View {
        Text("[Made with \(Image(systemName: "heart.fill")), made with Hack Club](https://hackclub.com/)")
            .multilineTextAlignment(.center)
            .tint(.secondary)
            .font(.footnote)
            .underline()
            .frame(maxWidth: .infinity)
    }
    
    var modifierConfig: some View {
        HStack {
            Text("Shortcut")
            
            Spacer()
            
            Button(action: {
                isEditingModifiers.toggle()
            }, label: {
                HStack {
                    let orderedModifiers: [Modifier] = Modifier.displayOrder.filter {
                        settings.preferredModifier.contains($0)
                    }
                    
                    if let first = orderedModifiers.first {
                        Image(systemName: first.imageSymbol)
                        
                        ForEach(orderedModifiers.dropFirst().indices, id: \.self) { index in
                            Image(systemName: "plus")
                            Image(systemName: orderedModifiers.dropFirst()[index].imageSymbol)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: 200, minHeight: 32, maxHeight: 32)
            })
            .buttonStyle(.bordered)
            .popover(isPresented: $isEditingModifiers, arrowEdge: .top) {
                modifierPopover
            }
        }
    }
    
    var modifierPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick modifier keys")
                .font(.headline)
            
            Text("Press one or more modifier key you want to use to activate the quick shortcuts")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(Modifier.allCases) { modifier in
                    Image(systemName: modifier.imageSymbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .padding(6)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .foregroundStyle(.thinMaterial)
                        )
                }
            }
        }
        .padding(12)
        .frame(width: 240)
    }
    
    private func shortcutConfig(for shortcut: Binding<ShortcutSettings>) -> some View {
        let orderedModifiers: [Modifier] = Modifier.displayOrder.filter {
            shortcut.wrappedValue.modifiers.contains($0)
        }
        
        return HStack {
            ForEach(orderedModifiers) { modifier in
                Image(systemName: modifier.imageSymbol)
                Image(systemName: "plus")
            }
            
            Text("\(shortcut.wrappedValue.index)")
                .frame(width: 16, alignment: .leading)
            
            Spacer()
            
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
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button(action: {
                        shortcut.wrappedValue.appBundleIdentifier = nil
                        shortcut.wrappedValue.appNameStatic = nil
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
                
                let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                let fallbackFromURL = url.deletingPathExtension().lastPathComponent
                shortcut.wrappedValue.appNameStatic = displayName ?? name ?? fallbackFromURL
            } else {
                let fallbackFromURL = url.deletingPathExtension().lastPathComponent
                shortcut.wrappedValue.appNameStatic = fallbackFromURL
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
                return ShortcutSettings(modifiers: [.command], index: number, appNameStatic: nil, appBundleIdentifier: nil)
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
        .frame(maxWidth: 400, maxHeight: 600)
}
