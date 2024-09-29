//
//  MainViewPhone.swift
//  APITesterPro
//
//  Created by Jaseem V V on 25.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI
import CoreData

struct CoreDataStore: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    var isLocalStore: Binding<Bool>? {
        get { self[CoreDataStore.self] }
        set { self[CoreDataStore.self] = newValue }
    }
}

@Observable
@available(iOS 17, *)
class WorkspaceState {
    private let app = App.shared
    var selectedWorkspace: EWorkspace
    
    init() {
        self.selectedWorkspace = self.app.getSelectedWorkspace()
    }
}

@available(iOS 17.0, *)
struct MainViewPhone: View {
    private let db = CoreDataService.shared
    private let uiViewState = UIViewState.shared
    private let app = App.shared
    @State private var isLocalStore = true
    var workspaceState = WorkspaceState()
    
    var body: some View {
        ProjectListView()
            .environment(\.managedObjectContext, isLocalStore ? db.localMainMOC : db.ckMainMOC)
            .environment(\.isLocalStore, $isLocalStore)
            .environment(workspaceState)
            .accentColor(uiViewState.accentColor)
            .tint(uiViewState.tintColor)
    }
}

@available(iOS 17.0, *)
struct ProjectListView: View {
    @State private var showWorkspaceSelection = false // State to control workspace popover visibility
    @Environment(\.isLocalStore) var isLocalStore
    @Environment(\.managedObjectContext) private var context
    @Environment(WorkspaceState.self) var workspaceState
    @State private var projects: [EProject] = []
    let db = CoreDataService.shared
    let app = App.shared
    
    var body: some View {
        NavigationStack {
            Text(isLocalStore?.wrappedValue == true ? "Local" : "iCloud")
            List {
                ForEach(projects) { project in
                    Text(project.name ?? "")
                }
            }
            .contentMargins(.top, 8)
            .listStyle(.plain)
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("Settings tapped")
                    }) {
                        Image(systemName: "gear")
                    }
                }
                // Add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Plus tapped")
                    }) {
                        Image(systemName: "plus")
                    }
                }
                // Bottom toolbar with workspace switcher
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: {
                        showWorkspaceSelection.toggle() // Show the popover
                    }) {
                        HStack {
                            Image(systemName: "iphone")
                            Text("Default workspace")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }
            }
            // Popover for workspace selection
            .popover(isPresented: $showWorkspaceSelection) {
                WorkspacesListView(showPopover: $showWorkspaceSelection)
            }
            .onAppear {
                self.loadProjects()
            }
            .onChange(of: isLocalStore?.wrappedValue) { oldValue, newValue in
                self.loadProjects()
            }
            .onChange(of: workspaceState.selectedWorkspace) { oldValue, newValue in
                self.loadProjects()
            }
        }
    }
    
    private func loadProjects() {
        Log.debug("Load projects")
        Log.debug("wsId: \(self.workspaceState.selectedWorkspace.getId())")
        let wsId = self.workspaceState.selectedWorkspace.getId()
        let fetchRequest: NSFetchRequest<EProject> = EProject.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EProject.created, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "workspace.id == %@ AND name != %@ AND markForDelete == %hdd", wsId, "", false)
        let moc = isLocalStore?.wrappedValue == true ? db.localMainMOC : db.ckMainMOC
        do {
            projects = try moc.fetch(fetchRequest)
        } catch {
            Log.error("Error fetching projects: \(error)")
        }
    }
}

//#Preview {
//    if #available(iOS 17.0, *) {
//        MainViewPhone()
//    } else {
//        // Fallback on earlier versions
//    }
//}
