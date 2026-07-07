//
//  NumLauncherApp.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import SwiftUI
import SwiftData

@main
struct NumLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var coordinator = AppCoordinator()
    
    var body: some Scene {
        MenuBarExtra("NumLauncher", systemImage: "number.sign") {
            Button("Settings") {
                coordinator.openSettings()
            }
            
            Divider()
            
            Button("Quit") {
                coordinator.quit()
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

