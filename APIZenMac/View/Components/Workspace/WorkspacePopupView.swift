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
    
    @State private var showingAddForm = false
    @State private var searchText = ""
    @State private var pickerSelection: Int = 0  // 0 = local, 1 = iCloud
    @State private var sortField: WorkspaceSortField = .name
    @State private var sortAscending: Bool = true
    
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    
    private let db = CoreDataService.shared
    
    enum WorkspaceSortField: String, CaseIterable {
        case name
        case created
    }
    
    let checkmarkWidth: CGFloat = 16
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    ExpandingSearchField(text: $searchText) { query in
                        // TODO: search impl
                        Log.debug("Search for: \(query)")
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Picker("", selection: $pickerSelection) {
                    Text("Local").tag(0)
                    Text("iCloud").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
                
                Group {
                    if pickerSelection == 0 {
                        WorkspaceListView { workspace in
                            handleWorkspaceSelect(workspace, container: .local)
                        }
                        .environment(\.managedObjectContext, self.db.localMainMOC)
                    } else {
                        WorkspaceListView { workspace in
                            handleWorkspaceSelect(workspace, container: .cloud)
                        }
                        .environment(\.managedObjectContext, self.db.ckMainMOC)
                    }
                }
                
                HStack {
                    // Sort button to the left
                    Menu {  // Using toggle so that the alignment of text shows fixed center with space for checkmark left as a constant. Using Button with HStack with Image and Text doesn't align the text by leaving the checkmark space constant when not checked.
                        // SECTION: Sort By
                        Text("Sort By")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        Toggle(isOn: Binding(
                            get: { sortField == .name },
                            set: { isOn in
                                if isOn { sortField = .name }
                            }
                        )) {
                            Text("by Name")
                        }

                        Toggle(isOn: Binding(
                            get: { sortField == .created },
                            set: { isOn in
                                if isOn { sortField = .created }
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
                                if isOn { sortAscending = true }
                            }
                        )) {
                            Text("Ascending")
                        }

                        Toggle(isOn: Binding(
                            get: { !sortAscending },
                            set: { isOn in
                                if isOn { sortAscending = false }
                            }
                        )) {
                            Text("Descending")
                        }

                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .help("Sort Workspaces")
                    
                    Spacer()
                    
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .help("Add Workspace")
                    .padding(.top, 4)
                }
                .padding(.top, 4)
            }
            .padding()
            .navigationDestination(isPresented: $showingAddForm) {
                AddWorkspaceFormView()
            }
        }
        .frame(width: 300, height: 400)
    }
    
    private func handleWorkspaceSelect(_ workspace: EWorkspace, container: CoreDataContainer) {
        Log.debug("ws item clicked: \(workspace.getName())")
        coreDataContainer = pickerSelection == 0 ? .local : .cloud  // Keeping this order of container, name, id just in case. We are listening to id change only but accessing container to save in registry in root view. This makes sure that container has the new value.
        workspaceName = workspace.getName()
        selectedWorkspaceId = workspace.getId()
        dismiss()
    }
}

// TODO: fix UI
struct AddWorkspaceFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Name", text: .constant(""))
            Button("Save") { dismiss() }
        }
        .padding()
        .navigationTitle("New Workspace")
    }
}
