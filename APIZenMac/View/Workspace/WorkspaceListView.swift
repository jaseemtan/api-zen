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
    @FetchRequest private var workspaces: FetchedResults<EWorkspace>

    let onSelect: (EWorkspace) -> Void

    init(selectedWorkspaceId: String, sortField: WorkspacePopupView.WorkspaceSortField, sortAscending: Bool, onSelect: @escaping (EWorkspace) -> Void) {
        self.selectedWorkspaceId = selectedWorkspaceId
        self.onSelect = onSelect
        let sortDescriptor: NSSortDescriptor
        switch sortField {
        case .manual:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.order, ascending: sortAscending)
        case .name:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.name, ascending: sortAscending)
        case .created:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.created, ascending: sortAscending)
        }
        _workspaces = FetchRequest(sortDescriptors: [sortDescriptor], animation: .default)
    }
    
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
