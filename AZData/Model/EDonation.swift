//
//  EDonation.swift
//  AZData
//
//  Created by Jaseem V V on 19/04/25.
//

import Foundation
import CoreData

public class EDonation: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "Env" }
    
    public func getId() -> String {
        return self.id ?? ""
    }
    
    public func getWsId() -> String {
        return ""
    }
    
    public func setWsId(_ id: String) {}
    
    public func getName() -> String {
        return ""
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
    
    public func setMarkedForDelete(_ status: Bool) {}
    
    public static func fromDictionary(_ dict: [String: Any], ctx: NSManagedObjectContext) -> EDonation? {
        guard let id = dict["id"] as? String else { return nil }
        guard let donation = self.db.createDonation(id: id, ctx: ctx) else { return nil }
        if let x = dict["created"] as? String { donation.created = Date.toUTCDate(x) }
        if let x = dict["modified"] as? String { donation.modified = Date.toUTCDate(x) }
        if let x = dict["amount"] as? Decimal { donation.amount = (x) as NSDecimalNumber }
        if let x = dict["deviceName"] as? String { donation.deviceName = x }
        if let x = dict["model"] as? String { donation.model = x }
        if let x = dict["systemName"] as? String { donation.systemName = x }
        if let x = dict["systemVersion"] as? String { donation.systemVersion = x }
        if let x = dict["tier"] as? Int64 { donation.tier = x }
        if let x = dict["vendorId"] as? String { donation.vendorId = x }
        if let x = dict["version"] as? Int64 { donation.version = x }
        return donation
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["created"] = self.created?.toUTCStr()
        dict["modified"] = self.modified?.toUTCStr()
        dict["id"] = self.id
        dict["amount"] = self.amount
        dict["deviceName"] = self.deviceName
        dict["model"] = self.model
        dict["systemName"] = self.systemName
        dict["systemVersion"] = self.systemVersion
        dict["tier"] = self.tier
        dict["vendorId"] = self.vendorId
        dict["version"] = self.version
        return dict
    }
}
