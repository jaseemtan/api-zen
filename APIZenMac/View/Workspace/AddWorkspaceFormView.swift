//
//  AddWorkspaceFormView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 09/12/25.
//

import SwiftUI
import AZCommon
import AZData
import CoreData

struct AddWorkspaceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String = ""
    @State var desc: String = ""
    @State var isSyncEnabled: Bool = true  // iCloud syncing enabled by default
    var isEdit: Bool = false
    var workspace: EWorkspace?  // Holds the workspace if edit mode
    
    private let db = CoreDataService.shared
    private let dbSvc = PersistenceService.shared
    
    var body: some View {
        ScrollView {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $desc)
                Toggle("iCloud Sync", isOn: $isSyncEnabled)
                    .disabled(isEdit)
            }
            .formStyle(.grouped)
            Button("Save") {
                saveWorkspace()
            }
            .buttonStyle(.borderedProminent)  // makes it respect system accent colour
            .disabled(isSaveButtonDisabled())
            Spacer()
        }
        .navigationTitle(isEdit ? "Edit Workspace" : "New Workspace")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func isSaveButtonDisabled() -> Bool {
        if !isEdit {
            return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard let ws = workspace else { return false }
        return !(ws.getName() != name || (ws.desc != nil && ws.desc! != desc))
    }
    
    private func saveWorkspace() {
        Log.debug("save workspace: \(name) - \(desc) - \(isSyncEnabled)")
        if !isEdit {
            self.dbSvc.createWorkspace(name: name, desc: desc, isSyncEnabled: isSyncEnabled)
        } else {
            workspace?.name = name
            workspace?.desc = desc
            self.db.saveMainContext()
        }
        dismiss()
    }
}
