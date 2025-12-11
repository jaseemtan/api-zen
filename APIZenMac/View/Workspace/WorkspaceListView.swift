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
    
    @State private var workspaces: [EWorkspace] = []
    @State private var dataManager: CoreDataManager<EWorkspace>?
    @State private var workspacePendingDelete: EWorkspace?
    @State private var showDeleteConfirmation = false
    
    @Environment(\.managedObjectContext) private var moc
    
    private var sortField: WorkspacePopupView.WorkspaceSortField
    private var sortAscending: Bool
    private var searchText: String
    private let db = CoreDataService.shared
    private let workspacesCacheName: String = "workspaces-cache"

    let onSelect: (EWorkspace, CoreDataContainer) -> Void
    let onEdit: (EWorkspace, CoreDataContainer) -> Void  // Add form nav view needs to be shown which is in parent view. So we call the parent view function.

    init(isProcessing: Binding<Bool>, selectedWorkspaceId: String, sortField: WorkspacePopupView.WorkspaceSortField, sortAscending: Bool, searchText: String, onSelect: @escaping (EWorkspace, CoreDataContainer) -> Void, onEdit: @escaping (EWorkspace, CoreDataContainer) -> Void) {
        _isProcessing = isProcessing
        self.selectedWorkspaceId = selectedWorkspaceId
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.sortField = sortField
        self.sortAscending = sortAscending
        self.searchText = searchText
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
        .onAppear(perform: {
            self.initDataManager()
        })
        .onChange(of: selectedWorkspaceId) { oldId, newId in
            if oldId != newId {
                Log.debug("Selected workspace id: \(newId)")
                if let ws = workspaces.first(where: { $0.getId() == newId }), let moc = ws.managedObjectContext {
                    onSelect(ws, self.db.getContainer(moc))
                }
            }
        }
        .onChange(of: sortField, { _, _ in
            self.initDataManager()  // reinit data manager with new sort descriptor to update the list ordering
        })
        .onChange(of: sortAscending, { _, _ in
            self.initDataManager()  // reinit data manager with new sort descriptor to update the list ordering
        })
        .onChange(of: searchText, { _, _ in
            self.initDataManager()
        })
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
    
    /// The query is cached. So multiple searches of the same parameters would not be that costly.
    func initDataManager() {
        Log.debug("ws view: init data manager")
        let fr = EWorkspace.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            fr.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = nil
        }
        fr.fetchBatchSize = 50
        if let dm = self.dataManager { dm.clearCache() }  // clear previous cache if already initialized before.
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, cacheName: self.workspacesCacheName, onChange: { workspaces in
            self.workspaces = workspaces
        })
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
        let wsId = workspace.getId()
        let isDeletingSelectedWs: Bool = wsId == selectedWorkspaceId
        self.db.deleteEntity(workspace, ctx: workspace.managedObjectContext)
        self.db.saveMainContext()
        WorkspacePopupView.WorkspacePopupState.deleteWorkspacePopupState(wsId)  // Delete any associated popup state stored in user defaults.
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
    
    private func getSortDescriptors() -> [NSSortDescriptor] {
        let sortDescriptor: NSSortDescriptor
        switch sortField {
        case .manual:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.order, ascending: sortAscending)
        case .name:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.name, ascending: sortAscending)
        case .created:
            sortDescriptor = NSSortDescriptor(keyPath: \EWorkspace.created, ascending: sortAscending)
        }
        return [sortDescriptor]
    }
}
