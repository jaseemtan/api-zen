//
//  APIZenMacTests.swift
//  APIZenMacTests
//
//  Created by Jaseem V V on 05/12/25.
//

import Testing
@testable import APIZenMac
internal import AZData

struct APIZenMacTests {
    private let windowRegistry = WindowRegistry()
    
    // MARK: - Window registry tests
    
    @Test
    func addWindowToRegistry() async {
        await self.windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        let count = await self.windowRegistry.getWindows().count
        #expect(count == 1)
        let window = await self.windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.windowIdx == 1)
        #expect(window!.parentWindowIdx == -1)
    }
    
    @Test
    func addTabToWindowInRegistry() async {
        await self.windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 2, workspaceId: "2", coreDataContainer: .cloud, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 3, workspaceId: "3", coreDataContainer: .cloud, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        let count = await self.windowRegistry.getWindows().count
        #expect(count == 1)
        let window = await self.windowRegistry.getWindow(windowIdx: 1)
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
    func addRemoveTabsToRegistry() async {
        await self.windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 2, workspaceId: "2", coreDataContainer: .cloud, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 3, workspaceId: "3", coreDataContainer: .cloud, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        let count = await self.windowRegistry.getWindows().count
        #expect(count == 1)
        var window = await self.windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.tabs.count == 2)
        await self.windowRegistry.removeTab(mainWindowIdx: 1, tabIdx: 3)
        window = await self.windowRegistry.getWindow(windowIdx: 1)
        #expect(window!.windowIdx == 1)
        #expect(window!.parentWindowIdx == -1)
        #expect(window!.tabs.count == 1)
        let tab1 = window!.tabs[2]
        #expect(tab1 != nil)
        #expect(tab1!.windowIdx == 2)
        #expect(tab1!.parentWindowIdx == 1)
    }
    
    @Test
    func convertTabToWindow() async {
        await self.windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.addTab(mainWindowIdx: 1, tabIdx: 2, workspaceId: "2", coreDataContainer: .cloud, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.convertTabToWindow(windowIdx: 1, tabIdx: 2)
        let count = await self.windowRegistry.getWindows().count
        #expect(count == 2)
        let window = await self.windowRegistry.getWindow(windowIdx: 1)
        #expect(window != nil)
        #expect(window!.tabs.count == 0)
    }
    
    @Test
    func convertWindowToTab() async {
        await self.windowRegistry.add(windowIndex: 1, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.add(windowIndex: 2, workspaceId: "1", coreDataContainer: .local, showNavigator: true, showInspector: true, showCodeView: true, isRestored: true)
        await self.windowRegistry.convertWindowToTab(windowIdx: 2, parentWindowIdx: 1)
        let count = await self.windowRegistry.getWindows().count
        #expect(count == 1)
        let window = await self.windowRegistry.getWindow(windowIdx: 1)
        #expect(window!.tabs.count == 1)
    }
}
