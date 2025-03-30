//
//  EProject.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

public class EProject: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Project" }
    
    public func getId() -> String {
        return self.id ?? ""
    }
    
    public func getWsId() -> String {
        return self.wsId ?? ""
    }
    
    public func setWsId(_ id: String) {
        self.wsId = id
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
    
    public override func willSave() {
        //if self.modified < AppState.editRequestSaveTs { self.modified = AppState.editRequestSaveTs }
    }
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EProject? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String else { return nil }
        guard let proj = self.db.createProject(id: id, wsId: wsId, name: "", desc: "", ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { proj.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { proj.modified = Date.toUTCDate(x) }
        if let x = dict["desc"] as? String { proj.desc = x }
        if let x = dict["name"] as? String { proj.name = x }
        if let x = dict["order"] as? NSDecimalNumber { proj.order = x }
        if let x = dict["version"] as? Int64 { proj.version = x }
        if let xs = dict["requests"] as? [[String: Any]] {
            xs.forEach { dict in
                if let req = ERequest.fromDictionary(dict, ctx: ctx) {
                    req.project = proj
                }
            }
        }
        if let xs = dict["methods"] as? [[String: Any]] {
            xs.forEach { dict in
                if let method = ERequestMethodData.fromDictionary(dict, ctx: ctx) {
                    method.project = proj
                }
            }
        }
        proj.markForDelete = false
        self.db.saveMainContext()
        return proj
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["desc"] = self.desc
        dict["id"] = self.id
        dict["wsId"] = self.wsId
        dict["name"] = self.name
        dict["order"] = self.order
        dict["version"] = self.version
        var xs: [[String: Any]] = []
        // requests
        let reqs = Self.db.getRequests(projectId: self.getId())
        reqs.forEach { req in
            xs.append(req.toDictionary())
        }
        dict["requests"] = xs
        xs = []
        // request methods
        let reqMethods = Self.db.getRequestMethodData(projId: self.getId())
        reqMethods.forEach { method in
            xs.append(method.toDictionary())
        }
        dict["methods"] = xs
        return dict
    }
}
