//
//  ERequestData.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData

public class ERequestData: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "RequestData" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> ERequestData? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String, let _type = dict["type"] as? Int64,
            let type = RequestDataType(rawValue: _type.toInt()), let _format = dict["fieldFormat"] as? Int64,
            let format = RequestBodyFormFieldFormatType(rawValue: _format.toInt())
            else { return nil }
        guard let reqData = self.db.createRequestData(id: id, wsId: wsId, type: type, fieldFormat: format, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { reqData.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { reqData.modified = Date.toUTCDate(x) }
        if let x = dict["key"] as? String { reqData.key = x }
        if let x = dict["value"] as? String { reqData.value = x }
        if let x = dict["version"] as? Int64 { reqData.version = x }
        if let files = dict["files"] as? [[String: Any]] {
            files.forEach { hm in
                if let file = EFile.fromDictionary(hm, ctx: ctx) {
                    file.requestData = reqData
                }
            }
        }
        if let image = dict["image"] as? [String: Any] {
            if let img = EImage.fromDictionary(image, ctx: ctx) {
                img.requestData = reqData
            }
        }
        reqData.markForDelete = false
        db.saveMainContext()
        return reqData
    }
    
    public func toDictionary() -> [String : Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["desc"] = self.desc
        dict["fieldFormat"] = self.fieldFormat
        dict["id"] = self.id
        dict["key"] = self.key
        dict["type"] = self.type
        dict["value"] = self.value
        dict["version"] = self.version
        dict["wsId"] = self.wsId
        var acc: [[String: Any]] = []
        if let xs = self.files?.allObjects as? [EFile] {
            xs.forEach { file in
                if !file.markForDelete { acc.append(file.toDictionary()) }
            }
        }
        dict["files"] = acc
        acc = []
        if let image = self.image {
            dict["image"] = image.toDictionary()
        }
        return dict
    }
    
    func copyEntity(wsId: String) -> ERequestData? {
        let id = Self.db.requestDataId()
        guard let type = RequestDataType(rawValue: self.type.toInt()) else { return nil }
        guard let format = RequestBodyFormFieldFormatType(rawValue: self.fieldFormat.toInt()) else { return nil }
        guard let reqData = Self.db.createRequestData(id: id, wsId: wsId, type: type, fieldFormat: format) else { return nil }
        reqData.desc = self.desc
        reqData.key = self.key
        reqData.value = self.value
        if let xs = self.files?.allObjects as? [EFile] {
            xs.forEach { file in
                let newFile = file.copyEntity(reqData)
                newFile?.requestData = reqData
            }
        }
        reqData.image = self.image?.copyEntity(reqData)
        return nil
    }
}
