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
