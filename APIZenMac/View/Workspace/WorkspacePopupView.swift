//
//  WorkspacePopupView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 08/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

/// View displayed when workspace name is clicked at the bottom of the main window. This shows workspace management view as a popup.
struct WorkspacePopupView: View {
    @Binding var selectedWorkspaceId: String
    @Binding var workspaceName: String
    @Binding var coreDataContainer: CoreDataContainer
    
    @State private var showAddForm = false
    @State private var searchText = ""
    @State private var pickerSelection: Int = 0  // 0 = local, 1 = iCloud
    @State private var sortField: WorkspaceSortField = .manual
    @State private var sortAscending: Bool = true
    /// Indicates if any list processing is happening. If child view is doing reordering, this will be set.
    @State private var isProcessing: Bool = false
    /// Holds the workspace that needs to be edited.
    @State private var editWorkspace: EWorkspace?
    
    @Environment(\.dismiss) private var dismiss

    private let db = CoreDataService.shared
    private let theme = ThemeManager.shared
    private let utils = AZUtils.shared
    
    enum WorkspaceSortField: String, CaseIterable, Codable, Equatable {
        case manual
        case name
        case created
    }
    
    /// For each workspace popup view part of the main view, it will have a user default state value.
    /// This stores the user selected preferences and restores from it each time. This is per workspace. Means, if we have multiple windows of the same workspace, all will have one preference stored.
    struct WorkspacePopupState: Identifiable, Codable {
        var workspaceId: String = ""
        var sortField: WorkspaceSortField = .manual
        var sortAscending: Bool = true
        
        var id: String { workspaceId }
        
        func encode() -> Data? {
            return try? JSONEncoder().encode(self)
        }
        
        func decode(_ data: Data?) -> WorkspacePopupState? {
            guard let data = data else { return nil }
            return try? JSONDecoder().decode(WorkspacePopupState.self, from: data)
        }
        
        /// Saves the state to user defaults.
        func saveWorkspacePopupState() {
            if let data = self.encode() {
                AZUtils.shared.setValue(key: self.getUserDefaultsKey(), value: data)
                Log.debug("saved state: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
            }
        }
        
        /// Restore the state from user defaults. Updates the current object. This should be invoked after setting the workspaceId.
        mutating func restoreWorkspacePopupState() {
            if workspaceId.isEmpty { return }
            if let data = AZUtils.shared.getValue(self.getUserDefaultsKey()) as? Data {
                if let state = self.decode(data) {
                    Log.debug("restored: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
                    self.sortField = state.sortField
                    self.sortAscending = state.sortAscending
                }
            }
        }
        
        private func getUserDefaultsKey() -> String {
            return "\(AZMConst.workspacePopupWindowStateKey)-\(self.workspaceId)"
        }
    }
    
    @State private var state: WorkspacePopupState = WorkspacePopupState()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    ExpandingSearchField() { query in
                        let text = query.trim()
                        Log.debug("Search for: \(query)")
                        searchText = text
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                
                HStack(spacing: 0) {  // Center aligned workspace container switcher
                    Spacer()
                    Picker("", selection: $pickerSelection) {
                        Text("Local").tag(0)
                        Text("iCloud").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)  // prevents expanding to the full width. Using fixedSize hugs the text closely without much padding.
                    Spacer()
                }
                .frame(maxWidth: .none, alignment: .leading)
                .padding(.vertical, 4)
                
                Group {
                    if pickerSelection == 0 {
                        WorkspaceListView(isProcessing: $isProcessing, selectedWorkspaceId: selectedWorkspaceId, sortField: sortField, sortAscending: sortAscending, searchText: searchText) { workspace, coreDataContainer in
                            handleWorkspaceSelect(workspace, container: coreDataContainer)
                        } onEdit: { workspace, coreDataContainer in
                            handleWorkspaceEdit(workspace, coreDataContainer)
                        }
                        .environment(\.managedObjectContext, self.db.localMainMOC)
                    } else {
                        WorkspaceListView(isProcessing: $isProcessing, selectedWorkspaceId: selectedWorkspaceId, sortField: sortField, sortAscending: sortAscending, searchText: searchText) { workspace, coreDataContainer in
                            handleWorkspaceSelect(workspace, container: coreDataContainer)
                        } onEdit: { workspace, coreDataContainer in
                            handleWorkspaceEdit(workspace, coreDataContainer)
                        }
                        .environment(\.managedObjectContext, self.db.ckMainMOC)
                    }
                }
                
                HStack {
                    // Sort button to the left
                    Menu {  // Using toggle so that the alignment of text shows fixed center with space for checkmark left as a constant. Using Button with HStack with Image and Text doesn't align the text by leaving the checkmark space constant when not checked.
                        // SECTION: Sort By
                        Text("Sort")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        Toggle(isOn: Binding(
                            get: { sortField == .manual },
                            set: { isOn in
                                if isOn {
                                    sortField = .manual
                                    state.sortField = sortField
                                    state.saveWorkspacePopupState()
                                }
                            }
                        )) {
                            Text("manual")
                        }
                        
                        Toggle(isOn: Binding(
                            get: { sortField == .name },
                            set: { isOn in
                                if isOn {
                                    sortField = .name
                                    state.sortField = sortField
                                    state.saveWorkspacePopupState()
                                }
                            }
                        )) {
                            Text("by Name")
                        }

                        Toggle(isOn: Binding(
                            get: { sortField == .created },
                            set: { isOn in
                                if isOn {
                                    sortField = .created
                                    state.sortField = sortField
                                    state.saveWorkspacePopupState()
                                }
                            }
                        )) {
                            Text("by Created")
                        }

                        Divider()

                        // SECTION: Order
                        Text("Order")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        Toggle(isOn: Binding(
                            get: { sortAscending },
                            set: { isOn in
                                if isOn {
                                    sortAscending = true
                                    state.sortAscending = sortAscending
                                    state.saveWorkspacePopupState()
                                }
                            }
                        )) {
                            Text("Ascending")
                        }

                        Toggle(isOn: Binding(
                            get: { !sortAscending },
                            set: { isOn in
                                if isOn {
                                    sortAscending = false
                                    state.sortAscending = sortAscending
                                    state.saveWorkspacePopupState()
                                }
                            }
                        )) {
                            Text("Descending")
                        }

                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(sortField == .manual ? .primary : theme.getForegroundStyle())
                    }
                    .help("Sort Workspaces")
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    if !isProcessing {
                        Button {
                            editWorkspace = nil
                            showAddForm = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .regular))
                                .imageScale(.medium)
                        }
                        .buttonStyle(.borderless)
                        .help("Add Workspace")
                        .padding(.top, 4)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .navigationDestination(isPresented: $showAddForm) {
                if let ws = editWorkspace {  // edit
                    AddWorkspaceFormView(name: ws.getName(), desc: ws.desc ?? "", isSyncEnabled: ws.isSyncEnabled, isEdit: true, workspace: ws)
                } else {  // add
                    AddWorkspaceFormView()
                }
            }
        }
        .onAppear {
            state.workspaceId = selectedWorkspaceId
            state.restoreWorkspacePopupState()
        }
        .task {
            pickerSelection = coreDataContainer == .local ? 0 : 1
            sortField = state.sortField
            sortAscending = state.sortAscending
        }
    }
    
    private func handleWorkspaceSelect(_ workspace: EWorkspace, container: CoreDataContainer) {
        Log.debug("ws item clicked: \(workspace.getName())")
        coreDataContainer = container  // Keeping this order of container, name, id just in case. We are listening to id change only but accessing container to save in registry in root view. This makes sure that container has the new value.
        workspaceName = workspace.getName()
        selectedWorkspaceId = workspace.getId()
        dismiss()
    }
    
    private func handleWorkspaceEdit(_ workspace: EWorkspace, _ container: CoreDataContainer) {
        Log.debug("handle edit")
        editWorkspace = workspace
        showAddForm = true
    }
}
