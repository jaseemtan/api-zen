//
//  ERequestMethodData.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData

public class ERequestMethodData: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "RequestMethodData" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> ERequestMethodData? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String else { return nil }
        guard let method = self.db.createRequestMethodData(id: id, wsId: wsId, name: "", ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { method.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { method.modified = Date.toUTCDate(x) }
        if let x = dict["name"] as? String { method.name = x }
        if let x = dict["order"] as? NSDecimalNumber { method.order = x }
        if let x = dict["version"] as? Int64 { method.version = x }
        method.markForDelete = false
        self.db.saveMainContext()
        return method
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["isCustom"] = self.isCustom
        dict["name"] = self.name
        dict["order"] = self.order
        dict["version"] = self.version
        dict["wsId"] = self.wsId
        return dict
    }
    
    /// Make a copy of the current request method with new id.
    public func copyEntity(_ toProj: EProject, ctx: NSManagedObjectContext) -> ERequestMethodData? {
        let destProj = Self.db.getProject(id: toProj.getId())
        let id = Self.db.requestMethodDataId()
        let wsId = toProj.getWsId()
        let method = Self.db.createRequestMethodData(id: id, wsId: wsId, name: self.getName(), ctx: ctx)
        method?.isCustom = self.isCustom
        method?.order = self.order
        method?.project = destProj
        return method
    }
}
