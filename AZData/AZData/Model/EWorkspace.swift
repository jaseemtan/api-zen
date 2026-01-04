//
//  EWorkspace.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData
import AZCommon

public class EWorkspace: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Workspace" }
    
    /// Checks if the default workspace does not have any change or is just after a reset (is new)
    var isInDefaultMode: Bool {
        return self.id == Self.db.defaultWorkspaceId && self.name == Self.db.defaultWorkspaceName && self.desc == Self.db.defaultWorkspaceDesc && (self.projects == nil || self.projects!.isEmpty)
    }
    
    public override func awakeFromInsert() {
        Log.debug("workspace is created \(self)")
        super.awakeFromInsert()
    }
    
    public override func willSave() {
        Log.debug("worspace will save: \(self)")
        super.willSave()
    }
    
    public func getId() -> String {
        return self.id ?? ""
    }
    
    public func getWsId() -> String {
        return self.getId()
    }
    
    public func setWsId(_ id: String) {
        self.id = id
    }
    
    public func getName() -> String {
        return self.name ?? ""
    }
    
    public func getCreated() -> Date {
        return self.created!.toLocalDate()
    }
    
    public func getCreatedUTC() -> Date {
        return self.created!
    }
    
    public func getModified() -> Date {
        return self.modified!.toLocalDate()
    }
    
    public func getModitiedUTC() -> Date {
        return self.modified!
    }
    
    public func setModified(_ date: Date) {
        self.modified = date.toUTC()
    }
    
    public func setModifiedUTC(_ date: Date) {
        self.modified = date
    }
    
    public func getVersion() -> Int64 {
        return self.version
    }
    
    public func setMarkedForDelete(_ status: Bool) {
        self.markForDelete = status
    }
    
    public static func fromDictionary(_ dict: [String: Any]) -> EWorkspace? {
        guard let id = dict["id"] as? String else { return nil }
        let isSyncEnabled = dict["isSyncEnabled"] as? Bool ?? true
        let ctx = isSyncEnabled ? self.db.ckMainMOC : self.db.localMainMOC
        guard let ws = self.db.createWorkspace(id: id, name: "", desc: "", isSyncEnabled: isSyncEnabled, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { ws.created = Date.toUTCDate(x) }
        if let x = dict["desc"] as? String { ws.desc = x }
        if let x = dict["isActive"] as? Bool { ws.isActive = x }
        ws.isSyncEnabled = isSyncEnabled
        if let x = dict["modified"] as? String { ws.modified = Date.toUTCDate(x) }
        if let x = dict["name"] as? String { ws.name = x }
        if let x = dict["order"] as? NSDecimalNumber { ws.order = x }
        if let x = dict["saveResponse"] as? Bool { ws.saveResponse = x }
        if let x = dict["syncDisabled"] as? String { ws.syncDisabled = Date.toUTCDate(x) }
        if let x = dict["version"] as? Int64 { ws.version = x }
        self.db.saveMainContext()
        if let xs = dict["projects"] as? [[String: Any]] {
            xs.forEach { x in
                if let proj = EProject.fromDictionary(x, ctx: ctx) {
                    proj.workspace = ws
                }
            }
        }
        if let xs = dict["envs"] as? [[String: Any]] {
            xs.forEach { dict in
                _ = EEnv.fromDictionary(dict, ctx: ctx)
            }
        }
        ws.markForDelete = false
        self.db.saveMainContext()
        Log.debug("dict: \(dict)")
        isSyncEnabled ? self.db.refreshAllCKManagedObjects() : self.db.refreshAllLocalManagedObjects()
        return ws
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["desc"] = self.desc
        dict["id"] = self.id
        dict["isActive"] = self.isActive
        dict["isSyncEnabled"] = self.isSyncEnabled
        dict["modified"] = self.modified?.toUTCStr()
        dict["name"] = self.name
        dict["order"] = self.order
        dict["saveResponse"] = self.saveResponse
        dict["syncDisabled"] = self.syncDisabled?.toUTCStr()
        dict["version"] = self.version
        var xs: [[String: Any]] = []
        let projs = Self.db.getProjects(wsId: self.getId())
        projs.forEach { proj in
            xs.append(proj.toDictionary())
        }
        dict["projects"] = xs
        let envxs = Self.db.getEnvs(wsId: self.getWsId())
        xs = []
        envxs.forEach { env in
            xs.append(env.toDictionary())
        }
        dict["envs"] = xs
        return dict
    }
}
