//
//  Models.swift
//  APIZen
//
//  Created by Jaseem V V on 17/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData

public protocol Entity: NSManagedObject, Hashable, Identifiable {
    var recordType: String { get }
    func getId() -> String
    func getWsId() -> String
    func setWsId(_ id: String)
    func getName() -> String
    /// Returns date converted to user's local time zone
    func getCreated() -> Date
    func getCreatedUTC() -> Date
    /// Returns date converted to user's local time zone
    func getModified() -> Date
    func getModitiedUTC() -> Date
    /// The modified fields get update on changing any property or relation. The date is in user's time zone.
    func setModified(_ date: Date)
    func setModifiedUTC(_ date: Date)
    func getVersion() -> Int64
    func setMarkedForDelete(_ status: Bool)
    func willSave()
}

extension Entity {
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
    
    // Hashable conformance
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.isEqual(rhs)
    }
}

