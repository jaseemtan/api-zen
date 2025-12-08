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

struct WorkspacePopupView: View {
    @Binding var selectedWorkspaceId: String
    @Binding var workspaceName: String
    @Binding var coreDataContainer: CoreDataContainer
    
    @State private var showingAddForm = false
    @State private var searchText = ""
    @State private var pickerSelection: Int = 0  // 0 = local, 1 = iCloud
    
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    
    private let db = CoreDataService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EWorkspace.name, ascending: true)],
        animation: .default
    )
    private var workspaces: FetchedResults<EWorkspace>
    
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
