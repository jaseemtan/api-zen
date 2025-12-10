//
//  WindowManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import Cocoa
import AZCommon
import AZData

/// Window management on macOS.

/// Bridge to AppKit to hook into app terminate event
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowRegistry = WindowRegistry.shared
    
    /// Called when user has quit the app and app is about to be terminated.
    func applicationWillTerminate(_ notification: Notification) {
        Log.debug("application will terminate")
        self.windowRegistry.saveOpenWindows()
    }
}

/// Keeps track of open windows. This can be used to get a list of open windows before terminating so that it can be restored on launch.
/// Runs on main thread. All access and mutations are main-thread safe.
@MainActor
class WindowRegistry {
    static let shared = WindowRegistry()
    private let utils = AZUtils.shared
    
    struct Entry: Identifiable, Codable {  // Codable to serialize
        let id: Int  // Is the identifier by default
        var workspaceId: String
        var coreDataContainer: CoreDataContainer
        var showNavigator: Bool  // Left pane
        var showInspector: Bool  // Right pane
        var showRequestComposer: Bool  // The center pane
        var showCodeView: Bool  // Center bottom pane
    }
    
    /// Reading windows is allowed from everywhere. Writing is allowed only within this file.
    private(set) var windows: [Int: Entry] = [:]
    
    
    /// Adds the given index and workspaceId to the window registry. The window index will be unique. So there won't be a case of getting the same index in one app lifecycle.
    func add(windowIndex: Int, workspaceId: String, coreDataContainer: CoreDataContainer, showNavigator: Bool, showInspector: Bool, showRequestComposer: Bool, showCodeView: Bool) {
        Log.debug("adding window index: \(windowIndex) with wsId: \(workspaceId) to window registry with container: \(coreDataContainer)")
        self.windows[windowIndex] = Entry(id: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showRequestComposer: showRequestComposer, showCodeView: showCodeView)
    }
    
    /// Removes the given window index from the window registry.
    func remove(windowIndex: Int) {
        Log.debug("removing window index: \(windowIndex) from window registry")
        self.windows.removeValue(forKey: windowIndex)
    }
    
    /// Encodes the entries if present.
    func encode() -> Data? {
        let entries = Array(self.windows.values).sorted { $0.id < $1.id }  // Since this is a dictionary the values are not in order. So we sort by id asc so that during restoration window 1 gets the first workspace in that order.
        return try? JSONEncoder().encode(entries)
    }
    
    /// Decodes the given encoded data to Entry array.
    func decode(_ data: Data?) -> [Entry]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([Entry].self, from: data)
    }
    
    /// Saves the list of open windows to user defaults.
    func saveOpenWindows() {
        if let data = self.encode() {
            self.utils.setValue(key: AZMConst.openWindowsKey, value: data)
        }
    }
    
    /// Returns the list of open windows that's saved in user defaults. This does not update the window registry. The registry should be updated only after displaying the window.
    func restoreOpenWindows() -> [Entry] {
        if let data = self.utils.getValue(AZMConst.openWindowsKey) as? Data {
            if let entries = self.decode(data) {
                return entries
            }
        }
        return []
    }
}
