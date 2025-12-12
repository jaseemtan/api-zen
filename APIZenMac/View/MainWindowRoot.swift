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
    
    // Pane preference is saved in the window registry because it's window specific. If I have same workspace in two different window and if I save workspace specific preference, then I can't have per window pane display. Hiding navigator will hide in all windows with the same workspace.
    // And this is saved for the open windows. If we close a window, these settings are cleared. The preference for the last window is saved.
    @SceneStorage("showNavigator")
    private var showNavigator: Bool = true  // Left pane

    @SceneStorage("showInspector")
    private var showInspector: Bool = true // Right pane

    @SceneStorage("showRequestComposer")
    private var showRequestComposer: Bool = true // The center pane

    @SceneStorage("showCodeView")
    private var showCodeView: Bool = true // Center bottom pane
    
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
    
    @State var isProcessing = true
    
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
            .environment(\.coreDataContainer, $coreDataContainer)
            .environment(\.managedObjectContext, coreDataContainer == .local ? self.db.localMainMOC : self.db.ckMainMOC)
            .onDisappear {
                Log.debug("WorkspaceWindowRoot onDisappear")
                // self.windowRegistry.remove(windowIndex: windowIndex)
            }
        } else {
            ProgressView()
                .controlSize(.small)
                .onAppear(perform: {
                    Log.debug("WorkspaceWindowRoot onAppear")
//                    Self.bootstrapWorkspaces = self.windowRegistry.restoreOpenWindows()
                    self.workspaceName = "Foo bar"
                })
                .task {
                    Log.debug("WorkspaceWindowRoot task")
                    // Assign a unique windowIndex per window
                    if windowIndex == 0 {
                        windowIndex = Self.nextWindowIndex
                        Self.nextWindowIndex += 1
                    }
                    // Make sure default workspace is created in local CoreData container.
                    _ = self.db.getDefaultWorkspace(ctx: self.db.localMainMOC)
                    isProcessing = false
                }
        }
    }
}
