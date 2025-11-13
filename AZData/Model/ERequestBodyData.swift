//
//  ERequestBodyData.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData

public class ERequestBodyData: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "RequestBodyData" }
    
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
        return self.id ?? ""
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> ERequestBodyData? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String else { return nil }
        guard let body = self.db.createRequestBodyData(id: id, wsId: wsId, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { body.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { body.modified = Date.toUTCDate(x) }
        if let x = dict["json"] as? String { body.json = x }
        if let x = dict["raw"] as? String { body.raw = x }
        if let x = dict["selected"] as? Int64 { body.selected = x }
        if let x = dict["xml"] as? String { body.xml = x }
        if let x = dict["version"] as? Int64 { body.version = x }
        if let hm = dict["binary"] as? [String: Any] {
            body.binary = ERequestData.fromDictionary(hm, ctx: ctx)
            body.binary?.binary = body
        }
        if let xs = dict["form"] as? [[String: Any]] {
            xs.forEach { hm in
                if let form = ERequestData.fromDictionary(hm, ctx: ctx) {
                    form.form = body
                }
            }
        }
        if let xs = dict["multipart"] as? [[String: Any]] {
            xs.forEach { hm in
                if let mp = ERequestData.fromDictionary(hm, ctx: ctx) {
                    mp.multipart = body
                }
            }
        }
        body.markForDelete = false
        self.db.saveMainContext()
        return body
    }
    
    public func toDictionary() -> [String : Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["wsId"] = self.wsId
        dict["json"] = self.json
        dict["raw"] = self.raw
        dict["selected"] = self.selected
        dict["xml"] = self.xml
        dict["version"] = self.version
        if let bin = self.binary {
            dict["binary"] = bin.toDictionary()
        }
        var acc: [[String: Any]] = []
        if let xs = self.form?.allObjects as? [ERequestData] {
            xs.forEach { reqData in
                if !reqData.markForDelete { acc.append(reqData.toDictionary()) }
            }
            dict["form"] = acc
        }
        acc = []
        if let xs = self.multipart?.allObjects as? [ERequestData] {
            xs.forEach { reqData in
                if !reqData.markForDelete { acc.append(reqData.toDictionary()) }
            }
            dict["multipart"] = acc
        }
        return dict
    }
    
    public func copyEntity(_ toProj: EProject) -> ERequestBodyData? {
        let id = Self.db.requestBodyDataId()
        let wsId = toProj.getWsId()
        let body = Self.db.createRequestBodyData(id: id, wsId: wsId)
        body?.json = self.json
        body?.raw = self.raw
        body?.selected = self.selected
        body?.xml = self.xml
        body?.binary = self.binary?.copyEntity(wsId: wsId)
        if let xs = self.form?.allObjects as? [ERequestData] {
            xs.forEach { form in
                let newForm = form.copyEntity(wsId: wsId)
                newForm?.form = body
            }
        }
        if let xs = self.multipart?.allObjects as? [ERequestData] {
            xs.forEach { multipart in
                let newMultipart = multipart.copyEntity(wsId: wsId)
                newMultipart?.multipart = body
            }
        }
        return body
    }
}
