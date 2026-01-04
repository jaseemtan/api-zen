//
//  EImage.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData
import AZCommon

public class EImage: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Image" }
    
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
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EImage? {
        guard let id = dict["id"] as? String, let wsId = dict["wsId"] as? String, let data = dict["data"] as? String,
        let name = dict["name"] as? String, let type = dict["type"] as? String else { return nil }
        guard let data1 = AZUtils.shared.stringToImageData(data) else { return nil }
        guard let image = self.db.createImage(imageId: id, data: data1, wsId: wsId, name: name, type: type, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { image.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { image.modified = Date.toUTCDate(x) }
        if let x = dict["isCameraMode"] as? Bool { image.isCameraMode = x }
        if let x = dict["version"] as? Int64 { image.version = x }
        image.markForDelete = false
        return image
    }
    
    public func toDictionary() -> [String : Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["wsId"] = self.wsId
        dict["name"] = self.name
        dict["type"] = self.type
        dict["data"] = AZUtils.shared.imageDataToString(self.data)
        dict["version"] = self.version
        return dict
    }
    
    public func copyEntity(_ reqData: ERequestData, ctx: NSManagedObjectContext) -> EImage? {
        let id = Self.db.imageId()
        let wsId = reqData.getWsId()
        guard let data = self.data else { return nil }
        guard let type = self.type else { return nil }
        guard let image = Self.db.createImage(imageId: id, data: data, wsId: wsId, name: self.getName(), type: type, ctx: ctx) else { return nil }
        image.requestData = reqData
        return image
    }
}
