//
//  EFile.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import AZCommon

public class EFile: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "File" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EFile? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String, let _data = dict["data"] as? String,
            let name = dict["name"] as? String, let _type = dict["type"] as? Int64, let type = RequestDataType(rawValue: _type.toInt()) else { return nil }
        var data: Data?
        if let aData = _data.data(using: .utf8) {
            data = aData
        } else {
            data = AZUtils.shared.stringToImageData(_data)
        }
        guard let data1 = data else { return nil }
        guard let file = self.db.createFile(fileId: id, data: data1, wsId: wsId, name: name, path: URL(fileURLWithPath: "/tmp/"), type: type, checkExists: true, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { file.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { file.modified = Date.toUTCDate(x) }
        if let x = dict["version"] as? Int64 { file.version = x }
        file.markForDelete = false
        return file
    }
    
    public func toDictionary() -> [String : Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["name"] = self.name
        dict["type"] = self.type
        dict["version"] = self.version
        if let data = self.data {
            if let str = String(data: data, encoding: .utf8) {
                dict["data"] = str
            } else {
                dict["data"] = AZUtils.shared.imageDataToString(data)
            }
        }
        dict["wsId"] = self.wsId
        return dict
    }
}
