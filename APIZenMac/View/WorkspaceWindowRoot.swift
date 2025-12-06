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
    // This is the per-window value managed by the WindowGroup
    @Binding var workspaceId: String?
    
    @Environment(\.openWindow) private var openWindow
    
    // Global flag so we only bootstrap once on a fresh launch
    private static var didInitWindows = false

    var body: some View {
        MainView(
            selectedWorkspaceId: Binding(
                get: { workspaceId ?? "default" },
                set: { workspaceId = $0 }
            )
        )
        .padding()
        .task {
            // 1. Only run the bootstrap once per app launch
            guard !Self.didInitWindows else { return }
            // 2. Only bootstrap on a *blank* (nil) window — not restored ones
            guard workspaceId == nil else { return }
            
            Self.didInitWindows = true

            // First auto-created window becomes ws1
            workspaceId = "ws1"
            // Second window is explicitly opened as ws2
            openWindow(value: "ws2")
        }
    }
}
