//
//  WorkspaceWindowRoot.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import SwiftUI
import AZData
import AZCommon

struct WorkspaceWindowRoot: View {
    @Environment(\.openWindow) private var openWindow
    
    // Per-window workspace id (each window has its own copy)
    @SceneStorage("workspaceId")
    private var workspaceId: String = "default"
    
    // Per-window index: Window #1, #2, ...
    @SceneStorage("windowIndex")
    private var windowIndex: Int = 0
    
    // Tracks whether this specific window has already been given
    // one of the initial bootstrap workspaces.
    @SceneStorage("didAssignBootstrapWorkspace")
    private var didAssignBootstrapWorkspace: Bool = false

    // --- Static (shared across all windows in this process) ---

    // Initial workspaces we want to open at launch.
    private static var bootstrapWorkspaces: [String] = ["ws1", "ws2"]
    private static var nextBootstrapIndex: Int = 0

    // Counter to assign "Window #N"
    private static var nextWindowIndex: Int = 1
    
    var body: some View {
        MainView(
            selectedWorkspaceId: Binding(
                get: { workspaceId },
                set: { workspaceId = $0 }
            ), windowIndex: windowIndex
        )
        .padding()
        .task {
            // 1. Assign a unique windowIndex per window
            if windowIndex == 0 {
                windowIndex = Self.nextWindowIndex
                Self.nextWindowIndex += 1
            }
            // 2. Bootstrap first two windows as ws1 / ws2.
            //    Each window only participates in bootstrap once.
            if !didAssignBootstrapWorkspace,
               Self.nextBootstrapIndex < Self.bootstrapWorkspaces.count {

                workspaceId = Self.bootstrapWorkspaces[Self.nextBootstrapIndex]
                didAssignBootstrapWorkspace = true
                Self.nextBootstrapIndex += 1

                // If there's still another bootstrap workspace left,
                // ask SwiftUI to open a new window for it.
                if Self.nextBootstrapIndex < Self.bootstrapWorkspaces.count {
                    openWindow(id: "workspace") // opens another WorkspaceWindowRoot
                }
            }
        }
    }
}
