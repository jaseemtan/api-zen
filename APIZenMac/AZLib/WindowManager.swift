//
//  WindowManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import Cocoa
import SwiftUI
import AZCommon
import AZData
import Combine

/// Window management on macOS.

/// Bridge to AppKit to hook into app terminate event
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowRegistry = WindowRegistry.shared
    
    /// Called when user has quit the app and app is about to be terminated.
    func applicationWillTerminate(_ notification: Notification) {
        Log.debug("application will terminate")
        Task {
            await self.windowRegistry.saveOpenWindows()
        }
    }
}

/// An actor which keeps track of open windows. This can be used to get a list of open windows before terminating so that it can be restored on launch.
/// Since it's an actor it can work safely in concurrency with multiple windows reading and writing data.
actor WindowRegistry {
    static let shared = WindowRegistry()
    static private var idx: Int = -1  // Use incIdx() to get new window index.
    
    private let utils = AZUtils.shared
    
    struct Entry: Identifiable, Codable {  // Codable to serialize
        var windowIdx: Int  // Is the identifier by default
        var workspaceId: String
        var coreDataContainer: CoreDataContainer
        var showNavigator: Bool  // Left pane
        var showInspector: Bool  // Right pane
        var showCodeView: Bool  // Center bottom pane
        var parentWindowIdx: Int = -1
        var isRestored: Bool
        /// Tabs for this window with [TabIdx : Entry]
        var tabs: [Int: Entry] = [:]
        
        var id: Int { windowIdx }
    }
    
    /// Holds the window entries.
    private var windows: [Int: Entry] = [:]
    
    /// User defaults key
    private let openWindowsKey = "openWindows"  // Adding this here because having a global static throws a warning on concurrency.
    
    /// Returns the current global window idx.
    func getIdx() -> Int {
        return Self.idx
    }
    
    /// Increments the current idx and returns the new global idx.
    func incIdx() -> Int {
        Self.idx += 1
        return Self.idx
    }
    
    /// Adds the given index and workspaceId to the window registry. The window index will be unique. So there won't be a case of getting the same index in one app lifecycle.
    func add(windowIndex: Int, workspaceId: String, coreDataContainer: CoreDataContainer, showNavigator: Bool, showInspector: Bool, showCodeView: Bool, isRestored: Bool) {
        Log.debug("adding window index: \(windowIndex) with wsId: \(workspaceId) to window registry with container: \(coreDataContainer)")
        self.windows[windowIndex] = Entry(windowIdx: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView, isRestored: isRestored)
    }
    
    /// Removes the given window index from the window registry.
    func remove(windowIndex: Int) {
        Log.debug("removing window index: \(windowIndex) from window registry")
        self.windows.removeValue(forKey: windowIndex)
    }
    
    /// Adds a tab to the given main window index. Tab is just another window with a parent window index.
    func addTab(mainWindowIdx: Int, tabIdx: Int, workspaceId: String, coreDataContainer: CoreDataContainer, showNavigator: Bool, showInspector: Bool, showCodeView: Bool, isRestored: Bool) {
        Log.debug("add tab: main window idx: \(mainWindowIdx) - tabIdx: \(tabIdx)")
        self.windows[mainWindowIdx]?.tabs[tabIdx] = Entry(windowIdx: tabIdx, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView, parentWindowIdx: mainWindowIdx, isRestored: isRestored)
    }
    
    /// Removes the tab from the main window with the given index.
    func removeTab(mainWindowIdx: Int, tabIdx: Int) {
        Log.debug("remove tab: mainWindowIdx: \(mainWindowIdx) - tabIdx: \(tabIdx)")
        self.windows[mainWindowIdx]?.tabs.removeValue(forKey: tabIdx)
    }
    
    /// Marks window as restored for the given window index.
    func markWindowAsRestored(windowIdx: Int) {
        self.windows[windowIdx]?.isRestored = true
    }
    
    /// Marks tab as restored for the given window index and tab index.
    func markTabAsRestored(windowIdx: Int, tabIdx: Int) {
        self.windows[windowIdx]?.tabs[tabIdx]?.isRestored = true
    }
    
    /// Returns the backed window entries variable
    func getWindows() -> [Int: Entry] {
        return self.windows
    }
    
    /// Get window with the given window index.
    func getWindow(windowIdx: Int) -> Entry? {
        return self.windows[windowIdx]
    }
    
    /// Get tab for the given window index and tab index.
    func getTab(windowIdx: Int, tabIdx: Int) -> Entry? {
        return self.windows[windowIdx]?.tabs[tabIdx]
    }
    
    /// Converts tab with tabIdx in the window with windowIdx to a standalone window. Standalone window will have parent id -1.
    func convertTabToWindow(windowIdx: Int, tabIdx: Int) {
        guard let tab = self.getTab(windowIdx: windowIdx, tabIdx: tabIdx) else { return }
        self.add(windowIndex: incIdx(), workspaceId: tab.workspaceId, coreDataContainer: tab.coreDataContainer, showNavigator: tab.showNavigator, showInspector: tab.showInspector, showCodeView: tab.showCodeView, isRestored: tab.isRestored)
        self.removeTab(mainWindowIdx: windowIdx, tabIdx: tabIdx)
    }
    
    /// Converts a standalone window with windowIdx to a tab in the parentWindowIdx.
    func convertWindowToTab(windowIdx: Int, parentWindowIdx: Int) {
        guard let window = self.getWindow(windowIdx: windowIdx) else { return }
        self.addTab(mainWindowIdx: parentWindowIdx, tabIdx: windowIdx, workspaceId: window.workspaceId, coreDataContainer: window.coreDataContainer, showNavigator: window.showNavigator, showInspector: window.showInspector, showCodeView: window.showCodeView, isRestored: window.isRestored)
        self.windows.removeValue(forKey: windowIdx)
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
            self.utils.setValue(key: self.openWindowsKey, value: data)
        }
    }
    
    /// Returns the list of open windows that's saved in user defaults. This does not update the window registry. The registry should be updated only after displaying the window.
    func restoreOpenWindows() -> [Entry] {
        if let data = self.utils.getValue(self.openWindowsKey) as? Data {
            if let entries = self.decode(data) {
                return entries
            }
        }
        return []
    }
}

class WindowManager {
    static let shared = WindowManager()
    
    func isWindowInTab(_ window: NSWindow?) -> Bool {
        guard let window = window else { return false }
        if let group = window.tabGroup {
            return group.windows.count > 1
        }
        return false
    }
}
