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

@available(iOS 17.0, *)
struct MainViewPhone: View {
    @State private var isLocalStore = true
    
    var body: some View {
        ProjectListView()
            .environment(\.managedObjectContext, CoreDataService.shared.localMainMOC)
            .environment(\.isLocalStore, $isLocalStore)
    }
}

@available(iOS 17.0, *)
struct ProjectListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EProject.created, ascending: true)],
        animation: .default
    ) private var projects: FetchedResults<EProject>
    
    @State private var showWorkspaceSelection = false // State to control workspace popover visibility
    @Environment(\.isLocalStore) var isLocalStore

    var body: some View {
        NavigationStack {
            Text(isLocalStore?.wrappedValue == true ? "Local" : "iCloud")
            List {
                ForEach(projects) { project in
                    Text(project.name ?? "")
                }
            }
            .contentMargins(.top, 8)
            .listStyle(.insetGrouped)
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
