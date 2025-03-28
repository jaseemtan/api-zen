//
//  EEnvVar.swift
//  APIZen
//
//  Created by Jaseem V V on 16/06/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

public class EEnvVar: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "EnvVar" }
    
    public func getId() -> String {
        return self.id ?? ""
    }
    
    public func getWsId() -> String {
        return self.env?.getWsId() ?? ""
    }
    
    public func setWsId(_ id: String) {
        fatalError("Not implemented")
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EEnvVar? {
        guard let id = dict["id"] as? String else { return nil }
        guard let envVar = self.db.createEnvVar(name: "", value: "", id: id, checkExists: true, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { envVar.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { envVar.modified = Date.toUTCDate(x) }
        if let x = dict["name"] as? String { envVar.name = x }
        if let x = dict["value"] as? String { envVar.value = x as String }
        if let x = dict["version"] as? Int64 { envVar.version = x }
        envVar.markForDelete = false
        return envVar
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["name"] = self.name
        dict["value"] = self.value ?? ""
        return dict
    }
}
