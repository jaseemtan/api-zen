//
//  AddFormView.swift
//  APITesterPro
//
//  Created by Jaseem V V on 28.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI

enum FormType {
    case workspace
    case project
}

@available(iOS 17.0, *)
struct AddFormView: View {
    @Binding var showAddFormView: Bool
    @State var formType: FormType = .workspace
    @State private var name: String = ""
    @State private var desc: String = ""
    @State private var iCloudSyncEnabled: Bool = true
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.showAddFormView = false
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(self.formType == .workspace ? "New Workspace" : "New Project")
                    .font(.headline)
                Spacer()
                Button(action: {
                    Log.debug("Save button tapped")
                    if (self.formType == .workspace) {
                        self.addNewWorkspace()
                    }
                }) {
                    Text("Save")
                        .foregroundColor(self.isSaveEnabled() ? .blue : .gray)
                }
                .disabled(!isSaveEnabled())
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 4, trailing: 16))
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Name")
                        .frame(width: 100, alignment: .leading)  // Label on the left
                    TextField("required", text: $name)  // TextField for input
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Description")
                        .frame(width: 100, alignment: .leading)  // Label on the left
                    TextField("optional", text: $desc)  // TextField for input
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if (self.formType == .workspace) {
                    HStack {
                        Toggle(isOn: $iCloudSyncEnabled) {
                            Text("iCloud Sync")
                        }
                    }
                }
                Spacer()
            }
           .padding()
        }
    }
    
    func isSaveEnabled() -> Bool {
        return !self.name.isEmpty
    }
    
    func addNewWorkspace() {
        
    }
}

