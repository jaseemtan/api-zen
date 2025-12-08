//
//  MainView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI
import CoreData
import AZData

struct MainView: View {
    @Binding var selectedWorkspaceId: String
    @Binding var coreDataContainer: CoreDataContainer
    let windowIndex: Int
    private let db = CoreDataService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window #\(windowIndex)")
                .font(.title2)

            HStack {
                Text("Workspace Id:")
                Text(selectedWorkspaceId)
                    .font(.headline)
            }
            
            HStack {
                Text("Container:")
                Text(coreDataContainer.rawValue)
                    .font(.headline)
            }

            Divider().padding(.vertical, 8)

            // Example buttons to change workspace for THIS window only
            Button("Use ws1 in this window") {
                selectedWorkspaceId = "ws1"
                coreDataContainer = .local
            }

            Button("Use ws2 in this window") {
                selectedWorkspaceId = "ws2"
                coreDataContainer = .local
            }

            Button("Use local-ws") {
                selectedWorkspaceId = "local-ws"
                coreDataContainer = .local
            }

            Button("Use icloud-ws") {
                selectedWorkspaceId = "icloud-ws"
                coreDataContainer = .cloud
            }

            Spacer()
        }
    }
}
