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
    @State var selectedWorkspaceId: String
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EWorkspace.name, ascending: true)],
        animation: .default
    )
    private var workspaces: FetchedResults<EWorkspace>

    let onSelect: (EWorkspace) -> Void

    var body: some View {
        List(workspaces) { workspace in
            NameDescView(imageName: "workspace", name: workspace.getName(), desc: workspace.desc, isDisplayCheckmark: workspace.getId() == selectedWorkspaceId)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(workspace)
                }
        }
    }
}
