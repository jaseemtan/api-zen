//
//  AddProjectView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

/// Add project form view displayed as a popup. Self contained. Save a new project.
struct AddProjectView: View {
    var workspaceId: String
    @Binding var name: String  // This is a binding so that if the popup gets closed, open it again preserves the typed value. Because the parent holds the state and it's live.
    @Binding var desc: String
    var isEdit: Bool = false
    @Binding var isProcessing: Bool
    
    var project: EProject?  // Holds the project if edit mode
    // Optional callback on save
    var onSave: ((EProject?) -> Void)?
    
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    
    private let db = CoreDataService.shared
    private let dbSvc = PersistenceService.shared
    
    var body: some View {
        ScrollView {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $desc)
            }
            .formStyle(.grouped)
            Button("Save") {
                saveProject()
            }
            .buttonStyle(.borderedProminent)  // makes it respect system accent colour
            .disabled(isSaveButtonDisabled())
            Spacer()
        }
        .navigationTitle(isEdit ? "Edit Project" : "New Project")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func isSaveButtonDisabled() -> Bool {
        if !isEdit {
            return name.trim().isEmpty
        }
        guard let project = project else { return false }
        return !(project.getName() != name || (project.desc != nil && project.desc! != desc))
    }
    
    private func saveProject() {
        Log.debug("add/edit project")
        isProcessing = true
        guard let ws = self.db.getWorkspace(id: workspaceId, ctx: moc) else {
            isProcessing = false
            return
        }
        if !isEdit {
            self.dbSvc.createProject(workspace: ws, name: name, desc: desc)
            name = ""
            desc = ""
            onSave?(nil)  // isProcessing will be set to false in the callback.
            dismiss()
        } else {
            if let project = project {
                isProcessing = true
                project.name = name
                project.desc = desc
                self.db.saveMainContext { _ in
                    DispatchQueue.main.async {
                        onSave?(project)  // isProcessing will be set to false in the callback.
                        name = ""
                        desc = ""
                        dismiss()
                    }
                }
            }
        }
    }
}
