//
//  MainWindowRoot.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import SwiftUI
import AZData
import AZCommon

/// The root window that instantiates the MainView window. This struct also saves open windows and restores it on re-launch. If there are no open windows during quit, the default workspace will be launched.
struct MainWindowRoot: View {
    @Environment(\.openWindow) private var openWindow
    
    /// This is set for the first window. Which is responsible for bootstrapping other windows.
    @State var isRootWindow: Bool
    /// Per-window index - 0, 1, etc.
    @State var windowIndex: Int = 0
    /// If this windows is part of a tab group, the index of the first window in the group.
    @State var parentWindowIndx: Int = -1
    // Indicates if the workspace is local or cloud based.
    @State private var coreDataContainer: CoreDataContainer = CoreDataContainer.local
    // Per-window workspace id (each window has its own copy)
    @State private var workspaceId: String = CoreDataService.shared.defaultWorkspaceId
    @State private var workspaceName: String = CoreDataService.shared.defaultWorkspaceName
    /// Selected project for the current workspace if present.
    @State private var project: EProject?
    /// Selected request for the project if present.
    @State private var request: ERequest?
    // Pane preference is saved in the window registry because it's window specific. If I have same workspace in two different window and if I save workspace specific preference, then I can't have per window pane display. Hiding navigator will hide in all windows with the same workspace.
    // And this is saved for the open windows. If we close a window, these settings are cleared. The preference for the last window is saved.
    @State private var showNavigator: Bool = true  // Left pane
    @State private var showInspector: Bool = true // Right pane
    @State private var showRequestComposer: Bool = true // The center pane
    @State private var showCodeView: Bool = true // Center bottom pane
    @State var isProcessing = true
    @State private var isTabbed = false
    @State private var window: NSWindow?
    
    
    
    private let windowRegistry = WindowRegistry.shared
    private let db = CoreDataService.shared
    
    var body: some View {
        if !isProcessing {
            MainView(
                selectedWorkspaceId: $workspaceId,
                coreDataContainer: $coreDataContainer,
                workspaceName: $workspaceName,
                project: $project,
                request: $request,
                windowIndex: windowIndex,
                showNavigator: $showNavigator,
                showInspector: $showInspector,
                showRequestComposer: $showRequestComposer,
                showCodeView: $showCodeView,
            )
            .frame(minWidth: 1024, idealWidth: 1280, minHeight: 600, idealHeight: 700, alignment: .center)
            .environment(\.coreDataContainer, $coreDataContainer)
            .environment(\.managedObjectContext, coreDataContainer == .local ? self.db.localMainMOC : self.db.ckMainMOC)
            .onChange(of: workspaceId, { oldValue, newValue in
                Log.debug("mwroot: wsId changed - old: \(oldValue) - new: \(newValue)")
                request = nil  // clear request and project
                project = nil
                if !isTabbed {  // NB: disabling this for tabs to prevent it from restoring a new window on launch for now. #tab
                    self.windowRegistry.add(windowIndex: windowIndex, workspaceId: newValue, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
                }
            })
            .onChange(of: showNavigator, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: newValue, showInspector: showInspector, showCodeView: showCodeView)
            })
            .onChange(of: showInspector, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: newValue, showCodeView: showCodeView)
            })
            .onChange(of: showCodeView, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: showInspector, showCodeView: newValue)
            })
            .onChange(of: project, { oldValue, newProj in
                let projId: String = newProj != nil ? newProj!.getId() : ""
                if projId == "" { request = nil }
                Log.debug("mwroot: selected project changed to \(projId)")
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView, projectId: projId, requestId: request != nil ? request!.getId() : "")
            })
            .onChange(of: request, { oldValue, newReq in
                let reqId: String = newReq != nil ? newReq!.getId() : ""
                Log.debug("mwroot: selected request changed: \(reqId)")
                // TODO: update window registry
            })
            .onDisappear {
                Log.debug("mwroot: on disappear")
                if isTabbed {
                    self.windowRegistry.removeTab(mainWindowIdx: parentWindowIndx, tabIdx: windowIndex)
                } else {
                    self.windowRegistry.remove(windowIndex: windowIndex)
                }
            }
        } else {
            // The first view that will be loaded which bootstraps the main view.
            ProgressView()
                .controlSize(.small)
                .onAppear(perform: {
                    Log.debug("mwroot: on appear")
                    if isRootWindow {
                        Log.debug("mwroot: root window \(windowIndex)")
                        _ = self.db.getDefaultWorkspace(ctx: self.db.localMainMOC)  // Make sure default workspace is created in local CoreData container.
                        self.windowRegistry.restoreOpenWindows()  // restore open window state from user defaults once.
                    } else {
                        Log.debug("mwroot: not root window \(windowIndex)")
                    }
                    self.restoreWindowState()  // restore current window state
                })
                // This gets called after onAppear. So we don't know if the window is in tabbed mode before `restoreWindowState()`.
                // Disabling this for now as appkit tabs does not work with swiftui window.
                .background(
                    WindowAccessor { window in
                        self.window = window
                        self.window?.windowIndex = windowIndex
                        isTabbed = WindowManager.shared.isWindowInTab(window)
                        Log.debug("mwroot: is tabbed: \(isTabbed)")
                    }
                )
                .task {  // called last
                    Log.debug("mwroot: task")
//                    self.restoreTabs()  // #tab
                    self.handleTab()  // #tab
                    isProcessing = false
                }
        }
    }
    
    /// If current window is opened as a SwiftUI tab in the window tab group, we should not add it as a main window. So clear it from window list. Otherwise tabs will be opened as new window on launch.
    /// Currently restoring tabs are not supported.
    /// #tab
    func handleTab() {
        if isTabbed {
            self.windowRegistry.remove(windowIndex: windowIndex)
        }
    }
    
    // #tab
    // Restoring tabs have issues because restored tabs are created using AppKit and for such tabs, new tab button does not work. Since the main window is SwiftUI and new tab is SwiftUI functionality.
    // So disabling this for now until SwiftUI has a way to open new tabs.
//    func restoreTabs() {
//        if isTabbed {
//            if let group = window?.tabGroup {
//                // The first window in the tab group is the main window for this group.
//                if let first = group.windows.first, let wIdx = first.windowIndex {
//                    self.parentWindowIndx = wIdx
//                    // TODO: update tab tracking for all windows. There is no APIs for tab move or joining, leaving tab group. So we need to update the state at some point in time.
//                    self.windowRegistry.addTab(mainWindowIdx: wIdx, tabIdx: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
//                }
//                group.windows.forEach { win in
//                    Log.debug("mwroot: win tab index: \(win.windowIndex ?? -1)")
//                }
//            }
//        }
//    }
    
    /// Restore window state for the current window. If there is no state, default values will be used. If there is state, it beings with 0, so the first window will get this state and so on.
    /// Since it's the root window, it will open other windows in order if present. The windows opened using this method has `isRootWindow` set to false. So this newly opened window will not open other windows.
    /// There will be only one root window when windows are restored automatically. When user press cmd + n, the new window it opens will be a root window. But since we set all windows opened flag, this new root window will not open additional windows.
    private func restoreWindowState() {
        self.windowIndex = self.windowRegistry.incIdx()
        let idx = self.windowIndex
        Log.debug("mwroot: restore window state - \(idx)")
        
        if let window = self.windowRegistry.getWindow(windowIdx: idx) {
            // Restore workspace data
            self.workspaceId = window.workspaceId
            self.coreDataContainer = CoreDataContainer(rawValue: window.coreDataContainer) ?? .local
            if let ws = self.db.getWorkspace(id: self.workspaceId, ctx: self.db.getMainMOC(container: self.coreDataContainer)) {
                self.workspaceName = ws.getName()
                Log.debug("mwroot: restoring ws: \(ws.getName())")
            }
            // Restore main window data
            self.showNavigator = window.showNavigator
            self.showInspector = window.showInspector
            self.showCodeView = window.showCodeView
            // Restore project, request data
            if window.projectId.isNotEmpty {
                let ctx = self.db.getMainMOC(container: coreDataContainer)
                if let proj = self.db.getProject(id: window.projectId, ctx: ctx) {
                    project = proj
                    if window.requestId.isNotEmpty {
                        if let req = self.db.getRequest(id: window.requestId, ctx: ctx) {
                            request = req
                        }
                    }
                }
            }
         
            // #tab
            // Restore tabs for the current window
//            let tabs = window.tabs
//            if tabs.count > 0 {
//                tabs.values.forEach { entry in
//                    Log.debug("mwroot: opening tab \(entry.windowIdx)")
//                    NSApp.openInNewTab(MainWindowRoot(isRootWindow: false, windowIndex: entry.windowIdx, parentWindowIndx: windowIndex))
//                }
//            }
            
            if isRootWindow && !self.windowRegistry.isAllWindowsOpened() {  // restore other windows
                let totalWindows: Int = min(self.windowRegistry.getWindows().count, 20)  // restore a max of 20 windows only.
                if totalWindows > 1 {
                    Log.debug("mwroot: opening windows")
                    for idx in 1..<totalWindows {
                        openWindow(id: "workspace", value: idx)
                    }
                }
                self.windowRegistry.setAllWindowsOpened()
            }
        } else {
            // This window is not present in the registry. Add it.
            self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer.rawValue, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
        }
    }
}
