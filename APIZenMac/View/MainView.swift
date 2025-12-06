//
//  MainView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI

struct MainView: View {
    @Binding var selectedWorkspaceId: String
    let windowIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window #\(windowIndex)")
                .font(.title2)

            HStack {
                Text("Workspace Id:")
                Text(selectedWorkspaceId)
                    .font(.headline)
            }

            Divider().padding(.vertical, 8)

            // Example buttons to change workspace for THIS window only
            Button("Use ws1 in this window") {
                selectedWorkspaceId = "ws1"
            }

            Button("Use ws2 in this window") {
                selectedWorkspaceId = "ws2"
            }

            Button("Use local-ws") {
                selectedWorkspaceId = "local-ws"
            }

            Button("Use icloud-ws") {
                selectedWorkspaceId = "icloud-ws"
            }

            Spacer()
        }
    }
}
