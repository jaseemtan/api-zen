//
//  MainView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI

struct MainView: View {
    @Binding var selectedWorkspaceId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Workspace Id:")
                Text(selectedWorkspaceId)
                    .font(.headline)
            }

            Divider().padding(.vertical, 8)

            Button("Use Local Workspace") {
                selectedWorkspaceId = "local-ws"
            }

            Button("Use iCloud Workspace") {
                selectedWorkspaceId = "icloud-ws"
            }

            Spacer()
        }
        .frame(minWidth: 320, minHeight: 200)
        .padding()
    }
}
