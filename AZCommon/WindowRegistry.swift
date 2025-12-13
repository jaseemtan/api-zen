//
//  WindowManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import SwiftUI

/// Window management for SwiftUI on macOS.
/// A class which keeps track of open windows. This can be used to get a list of open windows before terminating so that it can be restored on launch.
/// Since it's an actor it can work safely in concurrency with multiple windows reading and writing data.
public class WindowRegistry {
    public static let shared = WindowRegistry()
    public let maxWindowsToRestore = 20
    public let maxTabsToRestore = 50
    
    private var idx: Int = -1  // Use incIdx() to get new window index.
    /// Initially set to false. Once the initial windows are restored from storage on launch, this will be set to prevent overwriting open window states from storage.
    private var isRestored: Bool = false
    /// Flag indicating that all windows saved in storage which was restored on launch is opened. Once, further open window calls will not be made.
    private var isAllWindowOpened: Bool = false
    
    private let queue = DispatchQueue(label: "az-window-registry-queue")
    private let utils = AZUtils.shared
    
    public struct Entry: Identifiable, Codable {  // Codable to serialize
        /// The unique window index which can a sequential number. This is the identifier for the entry.
        public var windowIdx: Int
        /// The workspace id that the window is managing.
        public var workspaceId: String
        /// The core data container type for the given workspace. Can be local, cloud.
        public var coreDataContainer: String
        /// In a three pane view, show left pane, which is the navigator.
        public var showNavigator: Bool  // Left pane
        /// In a three pane view, show the right pane, which is the inspector.
        public var showInspector: Bool  // Right pane
        /// In a three pane view, show the center bottom pane, which is the code view.
        public var showCodeView: Bool  // Center bottom pane
        /// Parent window index in case of tab. Main window will have this value set to -1.
        public var parentWindowIdx: Int = -1
        /// Holds any tabs for this window with [TabIdx : Entry]
        public var tabs: [Int: Entry] = [:]
        /// The entry identifier.
        public var id: Int { windowIdx }
    }
    
    /// Holds the window entries.
    private var windows: [Int: Entry] = [:]
    
    /// User defaults key
    private var openWindowsKey = "openWindows"  // Adding this here because having a global static throws a warning on concurrency.
    
    public init() {
        if AppRuntime.isTesting {
            Log.debug("window registry in testing mode")
            self.openWindowsKey = "openWindows-test"  // use separate user defaults for testing
            self.clearAllSavedWindows()
        }
    }
    
    /// Returns the current global window idx.
    public func getIdx() -> Int {
        return self.idx
    }
    
    /// Increments the current idx and returns the new global idx.
    public func incIdx() -> Int {
        self.queue.sync {
            self.idx += 1
            return self.idx
        }
    }
    
    /// Adds the given index and workspaceId to the window registry. The window index will be unique. So there won't be a case of getting the same index in one app lifecycle.
    public func add(windowIndex: Int, workspaceId: String, coreDataContainer: String, showNavigator: Bool, showInspector: Bool, showCodeView: Bool) {
        Log.debug("adding window index: \(windowIndex) with wsId: \(workspaceId) to window registry with container: \(coreDataContainer)")
        self.windows[windowIndex] = Entry(windowIdx: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
    }
    
    /// Removes the given window index from the window registry.
    public func remove(windowIndex: Int) {
        Log.debug("removing window index: \(windowIndex) from window registry")
        self.windows.removeValue(forKey: windowIndex)
    }
    
    /// Adds a tab to the given main window index. Tab is just another window with a parent window index.
    public func addTab(mainWindowIdx: Int, tabIdx: Int, workspaceId: String, coreDataContainer: String, showNavigator: Bool, showInspector: Bool, showCodeView: Bool) {
        Log.debug("add tab: main window idx: \(mainWindowIdx) - tabIdx: \(tabIdx)")
        self.windows[mainWindowIdx]?.tabs[tabIdx] = Entry(windowIdx: tabIdx, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView, parentWindowIdx: mainWindowIdx)
    }
    
    /// Removes the tab from the main window with the given index.
    public func removeTab(mainWindowIdx: Int, tabIdx: Int) {
        Log.debug("remove tab: mainWindowIdx: \(mainWindowIdx) - tabIdx: \(tabIdx)")
        self.windows[mainWindowIdx]?.tabs.removeValue(forKey: tabIdx)
    }
    
    /// Returns the backed window entries variable
    public func getWindows() -> [Int: Entry] {
        return self.windows
    }
    
    /// Get window with the given window index.
    public func getWindow(windowIdx: Int) -> Entry? {
        return self.windows[windowIdx]
    }
    
    /// Get tab for the given window index and tab index.
    public func getTab(windowIdx: Int, tabIdx: Int) -> Entry? {
        return self.windows[windowIdx]?.tabs[tabIdx]
    }
    
    /// Converts tab with tabIdx in the window with windowIdx to a standalone window. Standalone window will have parent id -1.
    public func convertTabToWindow(windowIdx: Int, tabIdx: Int) {
        guard let tab = self.getTab(windowIdx: windowIdx, tabIdx: tabIdx) else { return }
        self.add(windowIndex: incIdx(), workspaceId: tab.workspaceId, coreDataContainer: tab.coreDataContainer, showNavigator: tab.showNavigator, showInspector: tab.showInspector, showCodeView: tab.showCodeView)
        self.removeTab(mainWindowIdx: windowIdx, tabIdx: tabIdx)
    }
    
    /// Converts a standalone window with windowIdx to a tab in the parentWindowIdx.
    public func convertWindowToTab(windowIdx: Int, parentWindowIdx: Int) {
        guard let window = self.getWindow(windowIdx: windowIdx) else { return }
        self.addTab(mainWindowIdx: parentWindowIdx, tabIdx: windowIdx, workspaceId: window.workspaceId, coreDataContainer: window.coreDataContainer, showNavigator: window.showNavigator, showInspector: window.showInspector, showCodeView: window.showCodeView)
        self.windows.removeValue(forKey: windowIdx)
    }
    
    /// Encodes the entries if present. Windows are sorted and ordered first updating the index to start from 0 sequentially.
    /// Tabs index starts after the window index. This is to make sure that on restoration, each window gets a unique index. Tabs can be moved to a standalone window. At that time, it should not replace an existing window.
    /// window 1 (0) -
    ///    tab 1 (2)
    ///    tab 2 (3)
    /// window 2 (1) -
    ///    tab 3 (4)
    ///    tab 4 (5)
    public func encode() -> Data? {
        let windowsCount = self.windows.values.count
        var tabIdx = windowsCount  // Order tabs sequentially starting after windows index. This is so that all windows get unique index on restoration.
        var entries: [Entry] = Array(self.windows.values).sorted { $0.id < $1.id }  // Since this is a dictionary the values are not in order. So we sort by id asc so that during restoration window 1 gets the first workspace in that order.
        let wlen = min(maxWindowsToRestore, entries.count)  // process only a limited set of windows
        for idx in 0..<wlen {
            entries[idx].windowIdx = idx  // order windows sequentially
            let tabs = entries[idx].tabs.values.sorted { tabA, tabB in
                tabA.windowIdx < tabB.windowIdx
            }
            entries[idx].tabs = [:]
            let tlen = min(maxTabsToRestore, tabs.count)  // process only a limited set of tabs.
            for tIdx in 0..<tlen {
                entries[idx].tabs[tabIdx] = tabs[tIdx]
                entries[idx].tabs[tabIdx]!.parentWindowIdx = entries[idx].windowIdx  // update tab's parent window id
                tabIdx += 1
            }
            Log.debug("window registry: entry prepared for window idx \(entries[idx].windowIdx)")
        }
        Log.debug("window registry: opened windows: \(entries.count)")
        return try? JSONEncoder().encode(entries)
    }
    
    /// Decodes the given encoded data to Entry array.
    public func decode(_ data: Data?) -> [Entry]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([Entry].self, from: data)
    }
    
    /// Saves the list of open windows to user defaults.
    public func saveOpenWindows() {
        if let data = self.encode() {
            self.utils.setValue(key: self.openWindowsKey, value: data)
            Log.debug("window manager: open windows state saved")
        }
    }
    
    /// Restores the list of open windows entries to the window registry state. This does not update the UI.
    public func restoreOpenWindows() {
        Log.debug("restore open windows")
        if isRestored {
            Log.debug("window registry: windows are restored. Ignoring restore window call.")
            return
        }
        if let data = self.utils.getValue(self.openWindowsKey) as? Data, let entries = self.decode(data) {
            self.windows = [:]
            entries.forEach { entry in
                self.windows[entry.windowIdx] = entry
            }
        } else {
            self.windows = [:]
        }
        self.isRestored = true
    }
    
    /// Clear all saved windows values
    public func clearAllSavedWindows() {
        self.utils.removeValue(self.openWindowsKey)
    }
    
    /// Resets window index count
    public func resetWindowIdx() {
        self.queue.sync {
            self.idx = -1
        }
    }
    
    /// Returns if all windows restored from the storage has been opened.
    public func isAllWindowsOpened() -> Bool {
        self.queue.sync {
            return self.isAllWindowOpened
        }
    }
    
    /// Sets the flag which will prevent overwriting the state from storage.
    public func setAllWindowsOpened() {
        self.queue.sync {
            self.isAllWindowOpened = true
        }
    }
}
