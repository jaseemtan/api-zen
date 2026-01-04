//
//  ERequest.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
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
    
    public func copyEntity(_ toProj: EProject, ctx: NSManagedObjectContext) -> ERequest? {
        let wsId = toProj.getWsId()
        let reqId = Self.db.requestId()
        let req = Self.db.createRequest(id: reqId, wsId: wsId, name: self.getName(), ctx: ctx)
        req?.desc = self.desc
        req?.envId = self.envId
        req?.order = self.order  // TODO: update order after adding the new copy to the list
        req?.validateSSL = self.validateSSL
        req?.url = self.url
        if let xs = toProj.requestMethods?.allObjects as? [ERequestMethodData] {
            let method = xs.first { meth in
                meth.getName() == self.method!.getName()
            }
            if method != nil {
                req?.method = method
            } else {
                req?.method = self.method?.copyEntity(toProj, ctx: ctx)
            }
        }
        req?.body = self.body?.copyEntity(toProj, ctx: ctx)
        if let xs = self.headers?.allObjects as? [ERequestData] {
            xs.forEach { reqData in
                let newReqData = reqData.copyEntity(wsId: wsId, ctx: ctx)
                newReqData?.header = req
            }
        }
        if let xs = self.params?.allObjects as? [ERequestData] {
            xs.forEach { reqData in
                let newReqData = reqData.copyEntity(wsId: wsId, ctx: ctx)
                newReqData?.param = req
            }
        }
        req?.project = toProj
        return req
    }
}
