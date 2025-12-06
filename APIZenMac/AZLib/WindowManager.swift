//
//  WindowManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import Cocoa
import AZCommon

/// Window management on macOS.

/// Bridge to AppKit to hook into app terminate event
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowRegistry = WindowRegistry.shared
    
    /// Called when user has quit the app and app is about to be terminated.
    func applicationWillTerminate(_ notification: Notification) {
        Log.debug("application will terminate")
        self.windowRegistry.windows.forEach { (key: Int, value: WindowRegistry.Entry) in
            Log.debug(value)
            // todo: save value to user defaults
        }
    }
}

/// Keeps track of open windows. This can be used to get a list of open windows before terminating so that it can be restored on launch.
/// Runs on main thread. All access and mutations are main-thread safe.
@MainActor
class WindowRegistry {
    static let shared = WindowRegistry()
    
    struct Entry: Identifiable {
        let id: Int
        var workspaceId: String
    }
    
    /// Reading windows is allowed from everywhere. Writing is allowed only within this file.
    private(set) var windows: [Int: Entry] = [:]
    
    
    /// Adds the given index and workspaceId to the window registry. The window index will be unique. So there won't be a case of getting the same index in one app lifecycle.
    func add(windowIndex: Int, workspaceId: String) {
        Log.debug("adding window index: \(windowIndex) with wsId: \(workspaceId) to window registry")
        self.windows[windowIndex] = Entry(id: windowIndex, workspaceId: workspaceId)
    }
    
    /// Removes the given window index from the window registry.
    func remove(windowIndex: Int) {
        Log.debug("removing window index: \(windowIndex) from window registry")
        self.windows.removeValue(forKey: windowIndex)
    }
}
