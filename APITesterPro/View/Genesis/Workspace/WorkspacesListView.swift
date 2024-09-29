//
//  WorkspacesListView.swift
//  APITesterPro
//
//  Created by Jaseem V V on 26.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI
import CoreData

@available(iOS 17.0, *)
struct WorkspacesListView: View {
    let db = CoreDataService.shared
    let app = App.shared
    let uiViewState = UIViewState.shared
    @Binding var showPopover: Bool
    @State private var selectedStore: String = "Local"
    let section = ["Local", "iCloud"]
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.isLocalStore) var isLocalStore
    @Environment(WorkspaceState.self) var workspaceState
    @State private var workspaces: [EWorkspace] = []
    @State private var showAddFormView = false

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Divider()
                Picker("", selection: $selectedStore) {
                    ForEach(section, id: \.self) { elem in
                        Text(" \(elem) ").tag(elem)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .controlSize(.large)
                .onChange(of: selectedStore) { oldValue, newValue in
                    if (newValue == "iCloud") {
                        Log.debug("icloud")
                        isLocalStore?.wrappedValue = false
                    } else {
                        Log.debug("Local")
                        isLocalStore?.wrappedValue = true
                    }
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                if (workspaces.isEmpty) {
                    Text("No \((isLocalStore?.wrappedValue ?? true) ? "local" : "iCloud") workspaces found")
                        .foregroundStyle(.gray)
                        .padding(EdgeInsets(top: 20, leading: 16, bottom: 8, trailing: 16))
                    Spacer()
                } else {
                    List {
                        ForEach(workspaces) { ws in
                            HStack {
                                Image("workspace")
                                    .renderingMode(.template)
                                    .foregroundStyle(self.uiViewState.getActiveColor())
                                Text(ws.name ?? "")
                                Spacer()
                                if self.workspaceState.selectedWorkspace.getId() == ws.getId() {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(self.uiViewState.getActiveColor())
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Log.debug("workspace row tapped")
                                self.setSelectedWorkspace(ws)
                                self.showPopover = false
                            }
                        }
                    }
                    .contentMargins(.top, 8)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Workspaces")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                showPopover = false // Dismiss the popover
            }, trailing: Button("Add") {
                Log.debug("Add workspace button tapped")
                showAddFormView.toggle()
            })
            .onAppear {
                self.selectedStore = (self.isLocalStore?.wrappedValue ?? true) ? "Local" : "iCloud"
                self.loadWorkspaces()
            }
            .onChange(of: isLocalStore?.wrappedValue) { oldValue, newValue in
                self.loadWorkspaces()
            }
            .onChange(of: showAddFormView, { oldValue, newValue in
                Log.debug("show add form view changed")
                if newValue == false && oldValue != newValue {
                    self.loadWorkspaces()
                }
            })
            .sheet(isPresented: $showAddFormView) {
                AddFormView(showAddFormView: $showAddFormView, formType: .workspace)
            }
        }
    }
    
    func loadWorkspaces() {
        Log.debug("Load workspaces")
        let fetchRequest: NSFetchRequest<EWorkspace> = EWorkspace.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EWorkspace.created, ascending: true)]
        let moc = isLocalStore?.wrappedValue == true ? db.localMainMOC : db.ckMainMOC
        do {
            workspaces = try moc.fetch(fetchRequest)
        } catch {
            Log.error("Error fetching workspaces: \(error)")
        }
    }
    
    func setSelectedWorkspace(_ ws: EWorkspace) {
        self.app.setSelectedWorkspace(ws)
        self.workspaceState.selectedWorkspace = ws
    }
}
