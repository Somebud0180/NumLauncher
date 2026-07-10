//
//  SettingsWindowController.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import AppKit
import SwiftUI
import Combine

final class ToastModel: ObservableObject {
    @Published var appName: String = ""
    @Published var appIcon: Image = Image(systemName: "app.grid")
    @Published var success: Bool?
}

@MainActor
final class ToastWindowController: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?
    private var window: NSWindow?
    private let model = ToastModel()
    
    /// A computed property that checks if the settings window is currently visible by accessing the `isVisible` property of the window.
    var isVisible: Bool {
        window?.isVisible == true
    }
    
    func updateSuccess(_ success: Bool, autoDismiss: Bool = true) {
        self.model.success = success
        
        if autoDismiss {
            Task { @MainActor in
                let delay = success ? 1.2 : 2.4
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                close()
            }
        }
    }
    
    /// Shows the settings window. If the window doesn't exist yet, it creates it using `makeWindowIfNeeded()`, then makes it key and orders it to the front.
    /// - Parameter settings: The shared configuration instance passed from the AppCoordinator.
    func show(appName: String, appIcon: Image) {
        model.appName = appName
        model.appIcon = appIcon
        let window = makeWindowIfNeeded()
        window.alphaValue = 0
        window.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1.0
        }
    }
    
    /// Closes the settings window by calling `performClose(nil)`.
    func close() {
        guard let window else { return }
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0.0
        } completionHandler: {
            window.orderOut(nil)
            self.model.appName = ""
            self.model.appIcon = Image(systemName: "app.grid")
            self.model.success = nil
        }
    }
    
    /// NSWindowDelegate method that gets called when the window is about to close.
    /// - Parameter notification: The notification object containing information about the window closing event.
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        onClose?()
    }
    
    /// Creates the settings window if it doesn't exist, sets up the hosting controller with the settings view and configures the window properties.
    /// - Parameter settings: The settings instance to inject into the view environment.
    /// - Returns: An `NSWindow` containing the settings view.
    private func makeWindowIfNeeded() -> NSWindow {
        if let window {
            return window
        }
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame
        
        let hostingController = NSHostingController(
            rootView: ToastView(model: model)
                .frame(minWidth: 176, maxWidth: 176, minHeight: 44, maxHeight: 44)
        )
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.autoresizingMask = .height
        
        let origin = NSPoint(
            x: (frame?.midX ?? 960) - (176 / 2),
            y: (frame?.maxY ?? 1080) - 32 - (44 / 2)
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: origin.x, y: origin.y, width: 176, height: 44),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.delegate = self
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        self.window = window
        return window
    }
}
