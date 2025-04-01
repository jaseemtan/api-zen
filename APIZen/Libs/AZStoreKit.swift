//
//  AZStoreKit.swift
//  APIZen
//
//  Created by Jaseem V V on 01/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import TPInAppReceipt
import AZCommon

public class AZStoreKit {
    /// Check if the user had purchased the paid app version from the App Store.
    public func isPaidAppPurchased() -> Bool {
        let lastPaidVersion = Decimal(string: "2.6")!
        do {
            let receipt = try InAppReceipt.localReceipt()
            let origAppVersionStr = receipt.originalAppVersion
            if let origAppVersion = Decimal(string: origAppVersionStr) {
                return origAppVersion <= lastPaidVersion
            }
        } catch {
            Log.error("Error getting original app version: \(error)")
        }
        return false
    }
}
