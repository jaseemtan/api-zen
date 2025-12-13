//
//  WindowManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 13/12/25.
//

import SwiftUI
import AppKit
import AZCommon

/// Bridge to AppKit to hook into app terminate event
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowRegistry = WindowRegistry.shared
    
    /// Called when user has quit the app and app is about to be terminated.
    func applicationWillTerminate(_ notification: Notification) {
        Log.debug("application will terminate")
        self.windowRegistry.saveOpenWindows()
    }
}

/// Window related methods for SwiftUI macOS.
class WindowManager {
    static let shared = WindowManager()
    
    /// Checks if current window is inside a tab.
    func isWindowInTab(_ window: NSWindow?) -> Bool {
        guard let window = window else { return false }
        if let group = window.tabGroup {
            return group.windows.count > 1
        }
        return false
    }
}

/// A bridge that let's us access the window running the SwiftUI view.
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
