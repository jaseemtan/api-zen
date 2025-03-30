//
//  EEnv.swift
//  APIZen
//
//  Created by Jaseem V V on 15/06/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

public class EEnv: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Env" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EEnv? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String else { return nil }
        guard let env = self.db.createEnv(name: "", envId: id, wsId: wsId, checkExists: true, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { env.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { env.modified = Date.toUTCDate(x) }
        if let x = dict["name"] as? String { env.name = x }
        if let x = dict["order"] as? NSDecimalNumber? { env.order = x }
        if let x = dict["version"] as? Int64 { env.version = x }
        if let xs = dict["variables"] as? [[String: Any]] {
            xs.forEach { hm in
                if let envVar = EEnvVar.fromDictionary(hm, ctx: ctx) {
                    envVar.env = env
                }
            }
        }
        env.markForDelete = false
        self.db.saveMainContext()
        return env
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["name"] = self.name
        dict["order"] = self.order
        dict["version"] = self.version
        dict["wsId"] = self.wsId
        let vars = Self.db.getEnvVars(envId: self.getId())
        var acc: [[String: Any]] = []
        vars.forEach { envVar in
            acc.append(envVar.toDictionary())
        }
        dict["variables"] = acc
        return dict
    }
}
