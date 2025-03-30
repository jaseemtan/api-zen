//
//  ERequest.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

public class ERequest: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Request" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> ERequest? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String else { return nil }
        guard let req = self.db.createRequest(id: id, wsId: wsId, name: "", ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { req.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { req.modified = Date.toUTCDate(x) }
        if let x = dict["envId"] as? String { req.envId = x }
        if let x = dict["desc"] as? String { req.desc = x }
        if let x = dict["name"] as? String { req.name = x }
        if let x = dict["order"] as? NSDecimalNumber { req.order = x }
        if let x = dict["validateSSL"] as? Bool { req.validateSSL = x }
        if let x = dict["url"] as? String { req.url = x }
        if let x = dict["version"] as? Int64 { req.version = x }
        if let dict = dict["method"] as? [String: Any] {
            if let method = ERequestMethodData.fromDictionary(dict, ctx: ctx) {
                req.method = method
            }
        }
        if let dict = dict["body"] as? [String: Any] {
            if let body = ERequestBodyData.fromDictionary(dict, ctx: ctx) {
                req.body = body
            }
        }
        if let xs = dict["headers"] as? [[String: Any]] {
            xs.forEach { dict in
                if let reqData = ERequestData.fromDictionary(dict, ctx: ctx) {
                    reqData.header = req
                }
            }
        }
        if let xs = dict["params"] as? [[String: Any]] {
            xs.forEach { dict in
                if let reqData = ERequestData.fromDictionary(dict, ctx: ctx) {
                    reqData.param = req
                }
            }
        }
        req.markForDelete = false
        self.db.saveMainContext()
        return req
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["wsId"] = self.wsId
        dict["desc"] = self.desc
        dict["name"] = self.name
        dict["envId"] = self.envId
        dict["order"] = self.order
        dict["validateSSL"] = self.validateSSL
        dict["url"] = self.url
        dict["version"] = self.version
        if let meth = self.method {
            dict["method"] = meth.toDictionary()
        }
        if let body = self.body {
            dict["body"] = body.toDictionary()
        }
        let headers = Self.db.getHeadersRequestData(self.getId())
        var xs: [[String: Any]] = []
        headers.forEach { header in
            xs.append(header.toDictionary())
        }
        dict["headers"] = xs
        xs = []
        let params = Self.db.getParamsRequestData(self.getId())
        params.forEach { param in
            xs.append(param.toDictionary())
        }
        dict["params"] = xs
        xs = []
        return dict
    }
}
