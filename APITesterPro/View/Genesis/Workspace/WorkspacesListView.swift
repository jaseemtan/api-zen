//
//  WorkspacesListView.swift
//  APITesterPro
//
//  Created by Jaseem V V on 26.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct WorkspacesListView: View {
    @Binding var showPopover: Bool
    @State private var selectedWorkspace: String = "Local"
    let section = ["Local", "iCloud"]
    @Environment(\.managedObjectContext) private var ctx
    let db = CoreDataService.shared
    @Environment(\.isLocalStore) var isLocalStore

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
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
                Spacer()
            }
            .navigationTitle("Workspaces")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                showPopover = false // Dismiss the popover
            })
        }
    }
}
