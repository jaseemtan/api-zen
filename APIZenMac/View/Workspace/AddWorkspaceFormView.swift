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
    @State private var name: String = ""
    @State private var desc: String = ""
    @State private var isSyncEnabled: Bool = true  // iCloud syncing enabled by default
    private let dbSvc = PersistenceService.shared
    
    var body: some View {
        ScrollView {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $desc)
                Toggle("iCloud Sync", isOn: $isSyncEnabled)
            }
            .formStyle(.grouped)
            Button("Save") {
                saveWorkspace()
            }
            .buttonStyle(.borderedProminent)  // makes it respect system accent colour
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer()
        }
        .navigationTitle("New Workspace")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func saveWorkspace() {
        Log.debug("save workspace: \(name) - \(desc) - \(isSyncEnabled)")
        self.dbSvc.createWorkspace(name: name, desc: desc, isSyncEnabled: isSyncEnabled)
        dismiss()
    }
}
