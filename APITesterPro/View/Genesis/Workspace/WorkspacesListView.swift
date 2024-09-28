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
    @Binding var showPopover: Bool
    @State private var selectedWorkspace: String = "Local"
    let section = ["Local", "iCloud"]
    @Environment(\.managedObjectContext) private var ctx
    let db = CoreDataService.shared
    @Environment(\.isLocalStore) var isLocalStore
    @State private var workspaces: [EWorkspace] = []

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Picker("", selection: $selectedWorkspace) {
                    ForEach(section, id: \.self) { elem in
                        Text(" \(elem) ").tag(elem)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .controlSize(.large)
                .onChange(of: selectedWorkspace) { oldValue, newValue in
                    if (newValue == "iCloud") {
                        Log.debug("icloud")
                        isLocalStore?.wrappedValue = false
                    } else {
                        Log.debug("Local")
                        isLocalStore?.wrappedValue = true
                    }
                }
                List {
                    ForEach(workspaces) { ws in
                        Text(ws.name ?? "")
                    }
                }
                .contentMargins(.top, 8)
                .listStyle(.plain)
            }
            .navigationTitle("Workspaces")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                showPopover = false // Dismiss the popover
            })
            .onAppear {
                self.selectedWorkspace = (self.isLocalStore?.wrappedValue ?? true) ? "Local" : "iCloud"
                self.loadWorkspaces()
            }
            .onChange(of: isLocalStore?.wrappedValue) { oldValue, newValue in
                self.loadWorkspaces()
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
}
