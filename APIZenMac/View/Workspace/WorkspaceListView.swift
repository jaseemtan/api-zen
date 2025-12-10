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
    
    @State private var workspacePendingDelete: EWorkspace?
    @State private var showDeleteConfirmation = false
    
    private var sortField: WorkspacePopupView.WorkspaceSortField
    private let db = CoreDataService.shared

    let onSelect: (EWorkspace, CoreDataContainer) -> Void
    let onEdit: (EWorkspace, CoreDataContainer) -> Void  // Add form nav view needs to be shown which is in parent view. So we call the parent view function.

    init(isProcessing: Binding<Bool>, selectedWorkspaceId: String, sortField: WorkspacePopupView.WorkspaceSortField, sortAscending: Bool, onSelect: @escaping (EWorkspace, CoreDataContainer) -> Void, onEdit: @escaping (EWorkspace, CoreDataContainer) -> Void) {
        _isProcessing = isProcessing
        self.selectedWorkspaceId = selectedWorkspaceId
        self.onSelect = onSelect
        self.onEdit = onEdit
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
                    .contextMenu {
                        Button("Edit") {
                            Log.debug("edit on ws: \(workspace.getName())")
                            editWorkspace(workspace: workspace)
                        }

                        Button("Delete", role: .destructive) {
                            Log.debug("delete on ws: \(workspace.getName())")
                            workspacePendingDelete = workspace
                            showDeleteConfirmation = true  // Display delete confirmation dialog
                        }
                    }
            }
            .onMove { indexSet, order in
                guard sortField == .manual else { return }
                reorderWorkspace(from: indexSet, to: order)
            }
        }
        .onChange(of: selectedWorkspaceId) { oldValue, newValue in
            if oldValue != newValue {
                Log.debug("Selected workspace id: \(newValue)")
                if let ws = workspaces.first(where: { $0.getId() == newValue }), let moc = ws.managedObjectContext {
                    onSelect(ws, self.db.getContainer(moc))
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this workspace?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let workspace = workspacePendingDelete {
                    deleteWorkspace(workspace: workspace)
                }
                workspacePendingDelete = nil
            }

            Button("Cancel", role: .cancel) {
                workspacePendingDelete = nil
            }
        }
    }
    
    func editWorkspace(workspace: EWorkspace) {
        if let moc = workspace.managedObjectContext {
            onEdit(workspace, self.db.getContainer(moc))
        }
    }
    
    /// Delete the workspace. If user deletes the existing workspace which is in the main window, the selection goes to default local workspace. If it's not present it will be created.
    /// The order of the default workspace while other workspaces are present in local will be count + 1. If no workspaces are present in local, the order will be 0.
    func deleteWorkspace(workspace: EWorkspace) {
        isProcessing = true
        let isDeletingSelectedWs: Bool = workspace.getId() == selectedWorkspaceId
        self.db.deleteEntity(workspace, ctx: workspace.managedObjectContext)
        self.db.saveMainContext()
        if isDeletingSelectedWs {  // Deleting selected workspace. Change selection to default workspace.
            let ws = self.db.getDefaultWorkspace()
            onSelect(ws, .local)
        }
        isProcessing = false
    }
    
    func reorderWorkspace(from source: IndexSet, to destination: Int) {
        guard source.first != nil else { return }
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
