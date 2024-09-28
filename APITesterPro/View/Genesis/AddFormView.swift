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
    private let uiViewState = UIViewState.shared
    private let dbSvc = PersistenceService.shared
    
    var body: some View {
        ZStack {
            // Hide keyboard on tapping outside the text field. This requires
            // wrapping VStack in a ZStack. VStack is on the top. Text field
            // responds to touch event first and it does not reach the overlay
            // for it to dismiss the keyboard.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UI.endEditing()
                }
            VStack {
                // Navbar
                HStack {
                    Button(action: {
                        self.showAddFormView = false
                    }) {
                        Text("Cancel")
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
                            .foregroundColor(self.isSaveEnabled() ? uiViewState.getActiveColor() : uiViewState.getDisabledColor())
                    }
                    .disabled(!isSaveEnabled())
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 4, trailing: 16))
                Divider()
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Name")
                            .frame(width: 100, alignment: .leading)
                        VTextField(placeholder: "required", text: $name)
                    }
                    HStack {
                        Text("Description")
                            .frame(width: 100, alignment: .leading)
                        VTextField(placeholder: "optional", text: $desc)
                    }
                    if (self.formType == .workspace) {
                        HStack {
                            Toggle(isOn: $iCloudSyncEnabled) {
                                Text("iCloud Sync")
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
                )
                Spacer()
            }
        }
    }
    
    func isSaveEnabled() -> Bool {
        return !self.name.isEmpty
    }
    
    func addNewWorkspace() {
        self.dbSvc.createWorkspace(name: name, desc: desc, isSyncEnabled: iCloudSyncEnabled)
        showAddFormView = false
    }
}
