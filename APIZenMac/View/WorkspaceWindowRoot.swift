//
//  WorkspaceWindowRoot.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import SwiftUI
import AZData
import AZCommon

/// The root window that instantiates the MainView window. This struct also saves open windows and restores it on re-launch. If there are no open windows during quit, the default workspace will be launched.
struct WorkspaceWindowRoot: View {
    @Environment(\.openWindow) private var openWindow
    
    // Per-window workspace id (each window has its own copy)
    @SceneStorage("workspaceId")
    private var workspaceId: String = CoreDataService.shared.defaultWorkspaceId
    
    @SceneStorage("workspaceName")
    private var workspaceName: String = ""  // Empty string to prevent displaying the default label while the state loads from user defaults and updates. Avoids flashing of default value.
    
    // Per-window index: Window #0, #1, etc.
    @SceneStorage("windowIndex")
    private var windowIndex: Int = 0
    
    // Indicates if the workspace is local or cloud based.
    @SceneStorage("coreDataContainer")
    private var coreDataContainer: CoreDataContainer = CoreDataContainer.local
    
    // Tracks whether this specific window has already been given one of the initial bootstrap workspaces.
    @SceneStorage("didAssignBootstrapWorkspace")
    private var didAssignBootstrapWorkspace: Bool = false

    // Static vars shared across all windows in this process

    // Initial workspaces we want to open at launch.
    private static var bootstrapWorkspaces: [WindowRegistry.Entry] = []
    private static var nextBootstrapIndex: Int = 0

    // Counter to assign "Window #N". Starts with 0.
    private static var nextWindowIndex: Int = 0
    
    private let windowRegistry = WindowRegistry.shared
    
    private let db = CoreDataService.shared
    
    var body: some View {
        MainView(
            selectedWorkspaceId: $workspaceId,
            coreDataContainer: $coreDataContainer,
            workspaceName: $workspaceName,
            windowIndex: windowIndex
        )
        .environment(\.coreDataContainer, $coreDataContainer)
        .environment(\.managedObjectContext, coreDataContainer == .local ? self.db.localMainMOC : self.db.ckMainMOC)
        .task {
            Log.debug("WorkspaceWindowRoot task")
            // Assign a unique windowIndex per window
            if windowIndex == 0 {
                windowIndex = Self.nextWindowIndex
                Self.nextWindowIndex += 1
            }
            // Make sure default workspace is created in local CoreData container.
            _ = self.db.getDefaultWorkspace(ctx: self.db.localMainMOC)
            // Bootstrap windows if present after restoration during init. Each window only participates in bootstrap once.
            if !didAssignBootstrapWorkspace,
               Self.nextBootstrapIndex < Self.bootstrapWorkspaces.count {
                let entry = Self.bootstrapWorkspaces[Self.nextBootstrapIndex]
                // set state
                workspaceId = entry.workspaceId
                coreDataContainer = entry.coreDataContainer
                if let ws = self.db.getWorkspace(id: workspaceId, ctx: self.db.getMainMOC(container: coreDataContainer)) {
                    workspaceName = ws.getName()
                }
                didAssignBootstrapWorkspace = true
                Self.nextBootstrapIndex += 1
                // If there's still another bootstrap workspace left, ask SwiftUI to open a new window for it.
                if Self.nextBootstrapIndex < Self.bootstrapWorkspaces.count {
                    openWindow(id: "workspace") // opens another WorkspaceWindowRoot
                }
            } else {
                if let ws = self.db.getWorkspace(id: workspaceId, ctx: self.db.getMainMOC(container: coreDataContainer)) {
                    workspaceName = ws.getName()
                }
//                _ = self.db.createWorkspace(id: "test-ws", name: "Test workspace", desc: "", isSyncEnabled: false, ctx: self.db.localMainMOC)
//                self.db.saveMainContext()
            }
            self.windowRegistry.add(windowIndex: windowIndex, workspaceId: workspaceId, coreDataContainer: coreDataContainer)
        }
        .onChange(of: workspaceId, { oldValue, newValue in
            Log.debug("wsId changed - old: \(oldValue) - new: \(newValue)")
            self.windowRegistry.add(windowIndex: windowIndex, workspaceId: newValue, coreDataContainer: coreDataContainer)
        })
        .onAppear {
            Log.debug("WorkspaceWindowRoot onAppear")            
            Self.bootstrapWorkspaces = self.windowRegistry.restoreOpenWindows()
        }
        .onDisappear {
            Log.debug("WorkspaceWindowRoot onDisappear")
            self.windowRegistry.remove(windowIndex: windowIndex)
        }
    }
}
