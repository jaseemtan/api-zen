//
//  APIZenMacTests.swift
//  AZCommon
//
//  Created by Jaseem V V on 13/12/25.
//

import Testing
@testable import AZCommon

struct WindowRegistryTests {
    // MARK: - Window registry tests
    
    @Test
    func addWindowToRegistry() {
        let windowRegistry = WindowRegistry()
        windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        let count = windowRegistry.getWindows().count
        #expect(count == 1)
        let window = windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.windowIdx == 1)
        #expect(window!.parentWindowIdx == -1)
    }
    
    @Test
    func addTabToWindowInRegistry() {
        let windowRegistry = WindowRegistry()
        windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 2, workspaceId: "2", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 3, workspaceId: "3", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        let count = windowRegistry.getWindows().count
        #expect(count == 1)
        let window = windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.windowIdx == 1)
        #expect(window!.parentWindowIdx == -1)
        #expect(window!.tabs.count == 2)
        let tab1 = window!.tabs[2]
        #expect(tab1 != nil)
        #expect(tab1!.windowIdx == 2)
        #expect(tab1!.parentWindowIdx == 1)
        let tab2 = window!.tabs[3]
        #expect(tab2 != nil)
        #expect(tab2!.windowIdx == 3)
        #expect(tab2!.parentWindowIdx == 1)
    }
    
    @Test
    func addRemoveTabsToRegistry() {
        let windowRegistry = WindowRegistry()
        windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 2, workspaceId: "2", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 3, workspaceId: "3", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        let count = windowRegistry.getWindows().count
        #expect(count == 1)
        var window = windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.tabs.count == 2)
        windowRegistry.removeTab(mainWindowIdx: 1, tabIdx: 3)
        window = windowRegistry.getWindow(windowIdx: 1)
        #expect(window!.windowIdx == 1)
        #expect(window!.parentWindowIdx == -1)
        #expect(window!.tabs.count == 1)
        let tab1 = window!.tabs[2]
        #expect(tab1 != nil)
        #expect(tab1!.windowIdx == 2)
        #expect(tab1!.parentWindowIdx == 1)
    }
    
    @Test
    func convertTabToWindow() {
        let windowRegistry = WindowRegistry()
        let windowId = windowRegistry.getIdx()
        let tabId = windowRegistry.incIdx()
        windowRegistry.add(windowIndex: windowId, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: windowId, tabIdx: tabId, workspaceId: "2", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.convertTabToWindow(windowIdx: windowId, tabIdx: tabId)
        let count = windowRegistry.getWindows().count
        #expect(count == 2)
        let window = windowRegistry.getWindow(windowIdx: windowId)
        #expect(window != nil)
        #expect(window!.tabs.count == 0)
        windowRegistry.resetWindowIdx()
    }
    
    @Test
    func convertWindowToTab() {
        let windowRegistry = WindowRegistry()
        windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.add(windowIndex: 2, workspaceId: "1", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.convertWindowToTab(windowIdx: 2, parentWindowIdx: 1)
        let count = windowRegistry.getWindows().count
        #expect(count == 1)
        let window = windowRegistry.getWindow(windowIdx: 1)
        #expect(window!.tabs.count == 1)
    }
    
    @Test
    func saveAndRestoreWindowsWithVaryingIndex() {
        let windowRegistry = WindowRegistry()
        defer {
            windowRegistry.clearAllSavedWindows()
        }
        let windowIdx1 = windowRegistry.incIdx()  // 0
        let tabIdx1 = windowRegistry.incIdx()     // 1
        let tabIdx2 = windowRegistry.incIdx()     // 2
        let tabIdx3 = windowRegistry.incIdx()     // 3
        let windowIdx2 = windowRegistry.incIdx()  // 4
        windowRegistry.add(windowIndex: windowIdx1, workspaceId: "0", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: windowIdx1, tabIdx: tabIdx1, workspaceId: "1", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: windowIdx1, tabIdx: tabIdx2, workspaceId: "2", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.addTab(mainWindowIdx: windowIdx1, tabIdx: tabIdx3, workspaceId: "3", coreDataContainer: "cloud", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.add(windowIndex: windowIdx2, workspaceId: "4", coreDataContainer: "local", showNavigator: true, showInspector: true, showCodeView: true)
        windowRegistry.removeTab(mainWindowIdx: windowIdx1, tabIdx: tabIdx1)  // 1 is removed
        var window = windowRegistry.getWindow(windowIdx: windowIdx1)
        #expect(window != nil)
        windowRegistry.saveOpenWindows()  // window 1 - idx: 0; window 2 - idx: 1; new tab 1 - idx: 3, tab 2 - idx: 4
        windowRegistry.resetWindowIdx()
        windowRegistry.restoreOpenWindows()  // total 4 windows. 2 main window, 2 tabs for 1st window.
        #expect(windowRegistry.getWindows().count == 2)
        window = windowRegistry.getWindow(windowIdx: 0)  // after restoring, idx starts with 0
        #expect(window != nil)
        #expect(window!.windowIdx == 0)
        #expect(window!.tabs.count == 2)
        var tab1 = window!.tabs[0]  // tab index starts from 2
        #expect(tab1 == nil)
        tab1 = window!.tabs[2]
        #expect(tab1 != nil)
        #expect(tab1!.windowIdx == 2)
        #expect(tab1!.parentWindowIdx == 0)
        var tab2 = window!.tabs[1]  // second tab is at index 3
        #expect(tab2 == nil)
        tab2 = window!.tabs[3]
        #expect(tab2 != nil)
        #expect(tab2!.windowIdx == 3)
        #expect(tab2!.parentWindowIdx == 0)
    }
}
