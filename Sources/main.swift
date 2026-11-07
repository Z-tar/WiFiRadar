import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        RadarWindowManager.shared.openWindow()
        return true
    }
}

// MARK: - Standalone Application Launch
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

// Open the Safari Pixel-Perfect 120Hz Wi-Fi Radar Window
RadarWindowManager.shared.openWindow()

app.run()
