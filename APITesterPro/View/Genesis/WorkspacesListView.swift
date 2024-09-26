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

    var body: some View {
        NavigationView {
            VStack {
                Text("Select your workspace")
                    .font(.body)
                    .padding()
                Spacer()
            }
            .navigationTitle("Workspaces")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                showPopover = false // Dismiss the popover
            })
            .frame(width: 300, height: 200)
            .padding()
        }
    }
}
