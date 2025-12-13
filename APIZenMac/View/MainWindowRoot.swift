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
    
    // Per-window workspace id (each window has its own copy)
    @State private var workspaceId: String = CoreDataService.shared.defaultWorkspaceId
    
    @State private var workspaceName: String = CoreDataService.shared.defaultWorkspaceName
    
    // Per-window index: Window #0, #1, etc.
    @State private var windowIndex: Int = 0
    
    // Indicates if the workspace is local or cloud based.
    @State private var coreDataContainer: CoreDataContainer = CoreDataContainer.local
    
    // Pane preference is saved in the window registry because it's window specific. If I have same workspace in two different window and if I save workspace specific preference, then I can't have per window pane display. Hiding navigator will hide in all windows with the same workspace.
    // And this is saved for the open windows. If we close a window, these settings are cleared. The preference for the last window is saved.
    @State private var showNavigator: Bool = true  // Left pane

    @State private var showInspector: Bool = true // Right pane

    @State private var showRequestComposer: Bool = true // The center pane

    @State private var showCodeView: Bool = true // Center bottom pane
    
    @State var isProcessing = true
    
    /// This is set for the first window. Which is responsible for bootstrapping other windows.
    @State var isRootWindow: Bool
    
    @State private var didSetSize = false
    
    private let windowRegistry = WindowRegistry.shared
    private let db = CoreDataService.shared
    
    
    var body: some View {
        if !isProcessing {
            MainView(
                selectedWorkspaceId: $workspaceId,
                coreDataContainer: $coreDataContainer,
                workspaceName: $workspaceName,
                windowIndex: windowIndex,
                showNavigator: $showNavigator,
                showInspector: $showInspector,
                showRequestComposer: $showRequestComposer,
                showCodeView: $showCodeView
            )
            .frame(minWidth: 1024, idealWidth: 1280, minHeight: 600, idealHeight: 700, alignment: .center)
            .environment(\.coreDataContainer, $coreDataContainer)
            .environment(\.managedObjectContext, coreDataContainer == .local ? self.db.localMainMOC : self.db.ckMainMOC)
            .onChange(of: workspaceId, { oldValue, newValue in
                Log.debug("mwroot: wsId changed - old: \(oldValue) - new: \(newValue)")
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: newValue, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
            })
            .onChange(of: showNavigator, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: newValue, showInspector: showInspector, showCodeView: showCodeView)
            })
            .onChange(of: showInspector, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: newValue, showCodeView: showCodeView)
            })
            .onChange(of: showCodeView, { oldValue, newValue in
                self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: newValue)
            })
            .onDisappear {
                Log.debug("mwroot: on disappear")
                self.windowRegistry.remove(windowIndex: windowIndex)
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
                .task {
                    Log.debug("mwroot: task")
                    isProcessing = false
                }
        }
    }
    
    /// Restore window state for the current window. If there is no state, default values will be used. If there is state, it beings with 0, so the first window will get this state and so on.
    /// Since it's the root window, it will open other windows in order if present. The windows opened using this method has `isRootWindow` set to false. So this newly opened window will not open other windows.
    /// There will be only one root window when windows are restored automatically. When user press cmd + n, the new window it opens will be a root window. But since we set all windows opened flag, this new root window will not open additional windows.
    private func restoreWindowState() {
        self.windowIndex = self.windowRegistry.incIdx()
        let idx = self.windowIndex
        Log.debug("mwroot: restore window state - \(idx)")
        if let window = self.windowRegistry.getWindow(windowIdx: idx) {
            self.workspaceId = window.workspaceId
            self.coreDataContainer = window.coreDataContainer
            if let ws = self.db.getWorkspace(id: self.workspaceId, ctx: self.db.getMainMOC(container: self.coreDataContainer)) {
                self.workspaceName = ws.getName()
                Log.debug("mwroot: restoring ws: \(ws.getName())")
            }
            self.showNavigator = window.showNavigator
            self.showInspector = window.showInspector
            self.showCodeView = window.showCodeView
         
            //TODO: restore tabs for the current window
            
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
            self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer, showNavigator: showNavigator, showInspector: showInspector, showCodeView: showCodeView)
        }
    }
}
