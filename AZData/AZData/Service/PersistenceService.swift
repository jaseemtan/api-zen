//
//  PersistenceService.swift
//  AZData
//
//  Created by Jaseem V V on 09/12/25.
//

import CoreData
import AZCommon

public class PersistenceService {
    public static let shared = PersistenceService()
    private lazy var db = { CoreDataService.shared }()
    
    // Add new workspace. The workspace order will be incremented.
    public func createWorkspace(name: String, desc: String, isSyncEnabled: Bool) {
        let ctx = isSyncEnabled ? self.db.ckMainMOC : self.db.localMainMOC
        let order = self.db.getOrderOfLastWorkspace(ctx: ctx).inc()
        Log.debug("Last workspace order: \(order)")
        if let ws = self.db.createWorkspace(id: self.db.workspaceId(), name: name, desc: desc, isSyncEnabled: isSyncEnabled, ctx: ctx) {
            ws.order = order
            self.db.saveMainContext()
        }
    }
    
    /// Add new project in the given workspace.
    public func createProject(workspace: EWorkspace, name: String, desc: String) {
        guard let ctx = workspace.managedObjectContext else { return }
        let wsId = workspace.getId()
        let order = self.db.getOrderOfLastProject(wsId: wsId, ctx: ctx).inc()
        if let proj = self.db.createProject(id: self.db.projectId(), wsId: wsId, name: name, desc: desc, ws: workspace, ctx: ctx) {
            proj.order = order
            proj.workspace = workspace
            self.db.saveMainContext()
        }
    }
}
