//
//  AppDelegate.swift
//  NumLauncher
//
//  Created by Assistant on 7/7/26.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private let lockFilePath = NSTemporaryDirectory() + "com.numlauncher.unique.lock"
    private var lockFileDescriptor: Int32 = -1
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !acquireInstanceLock() {
            showDuplicateInstanceAlert()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        releaseInstanceLock()
    }
    
    // MARK: - Duplicate Instance Detection
    private func acquireInstanceLock() -> Bool {
        let fd = open(lockFilePath, O_CREAT | O_RDWR, 0o666)
        guard fd != -1 else { return true } // If can't open, proceed anyway
        var flockStruct = flock(l_start: 0, l_len: 0, l_pid: 0, l_type: Int16(F_WRLCK), l_whence: Int16(SEEK_SET))
        let result = fcntl(fd, F_SETLK, &flockStruct)
        if result == -1 { // Lock failed: already locked
            close(fd)
            return false
        } else {
            lockFileDescriptor = fd
            return true
        }
    }
    
    private func releaseInstanceLock() {
        guard lockFileDescriptor != -1 else { return }
        close(lockFileDescriptor)
        lockFileDescriptor = -1
        try? FileManager.default.removeItem(atPath: lockFilePath)
    }
    
    // MARK: - Alert UI
    private func showDuplicateInstanceAlert() {
        let alert = NSAlert()
        alert.messageText = "NumLauncher is already open"
        alert.informativeText = "NumLauncher is already running. Do you want to close the previous instance?"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Quit Previous Instance")
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            quitPreviousInstance()
        } else {
            NSApp.terminate(nil)
        }
    }
    
    // MARK: - Quit the Previous Instance
    private func quitPreviousInstance() {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        for app in runningApps {
            if app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                app.forceTerminate()
            }
        }
    }
}
