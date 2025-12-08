//
//  WorkspaceListView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 08/12/25.
//

import SwiftUI
import CoreData
import AZData

struct WorkspaceListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EWorkspace.name, ascending: true)],
        animation: .default
    )
    private var workspaces: FetchedResults<EWorkspace>

    let onSelect: (EWorkspace) -> Void

    var body: some View {
        List(workspaces) { workspace in
            Text(workspace.getName())
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)  // stretch across row
                .contentShape(Rectangle())  // full row is hit-testable
                .onTapGesture {
                    onSelect(workspace)
                }
        }
    }
}
