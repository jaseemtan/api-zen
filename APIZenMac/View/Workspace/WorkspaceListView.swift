//
//  WorkspaceListView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 08/12/25.
//

import SwiftUI
import CoreData
import AZCommon
import AZData
import Foundation

struct WorkspaceListView: View {
    /// Indicates if list element is being processed. For example, list reordering operating, setting the index for all items in the list after a reorder.
    /// This is a binding because we need to update the state in parent view when change happens in this view.
    @Binding var isProcessing: Bool
    @State var selectedWorkspaceId: String
    @FetchRequest private var workspaces: FetchedResults<EWorkspace>
    @Environment(\.coreDataContainer) private var coreDataContainer
    
    private var sortField: WorkspacePopupView.WorkspaceSortField
    private let db = CoreDataService.shared

    let onSelect: (EWorkspace) -> Void

    init(isProcessing: Binding<Bool>, selectedWorkspaceId: String, sortField: WorkspacePopupView.WorkspaceSortField, sortAscending: Bool, onSelect: @escaping (EWorkspace) -> Void) {
        _isProcessing = isProcessing
        self.selectedWorkspaceId = selectedWorkspaceId
        self.onSelect = onSelect
        self.sortField = sortField
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
        List(selection: $selectedWorkspaceId) {
            ForEach(workspaces) { workspace in
                NameDescView(imageName: "workspace", name: "\(workspace.getName()) - \(workspace.order!)", desc: workspace.desc, isDisplayCheckmark: workspace.getId() == selectedWorkspaceId)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .tag(workspace.getId())
            }
            .onMove { indexSet, order in
                reorderWorkspace(from: indexSet, to: order)
            }
        }
        .onChange(of: selectedWorkspaceId) { oldValue, newValue in
            if oldValue != newValue {
                Log.debug("Selected workspace id: \(newValue)")
                if let ws = workspaces.first(where: { $0.getId() == newValue }) {
                    onSelect(ws)
                }
            }
        }
    }
    
    func reorderWorkspace(from source: IndexSet, to destination: Int) {
        guard let fromIndex = source.first else { return }
        isProcessing = true
        var workspaces = workspaces.map { $0 }
        workspaces.move(fromOffsets: source, toOffset: destination)  // does the move operation inserting item to the correct order in the local workspace copy. After which we set the order for this list. Saving will update the store and redraw the UI.
        DispatchQueue.main.async {
            for (index, workspace) in workspaces.enumerated() {
                workspace.order = NSDecimalNumber(string: "\(index)")
            }
            self.db.saveMainContext()
            isProcessing = false
        }
    }
}
