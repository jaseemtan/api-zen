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
import StoreKit

public struct IAPID {
    /// Consumables
    public static let thanks = "net.jsloop.APIZen.Thanks"
    public static let thankYou = "net.jsloop.APIZen.Thankyou"
    public static let thankYouVeryMuch = "net.jsloop.APIZen.Thankyouverymuch"
}

public class AZStoreKit: NSObject {
    public static let shared = AZStoreKit()
    let productIds: Set<String> = [IAPID.thanks, IAPID.thankYou, IAPID.thankYouVeryMuch]
    var products: [SKProduct] = []
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
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
    
    /// Retrieves the list of In-App products from the App Store.
    public func getListOfInAppProducts() {
        let productRequest = SKProductsRequest(productIdentifiers: self.productIds)
        productRequest.delegate = self
        productRequest.start()
    }
    
    /// Make a purchase of the given In-App product
    public func makePurchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// Backup data for storing user's total donations
    public func saveTotalDonationAmountToCloudKitKVStore() {
        // todo:
    }
    
    /// Backup data retrieving user's total donations. The value from CloudKit Core Data store takes precedence in case of a mismatch.
    public func getTotalDonationAmountFromCloudKitKVStore() {
        // todo:
    }
    
    public func saveDonationToDB() {
        // donation amount - decimal (for regions other than US with price adjustment)
        // currency - name, symbol
        // date - day, month, year, time
        // Device meta that made the purchase
    }
    
    public func getDonationsFromDB() {
        
    }
    
    public func getTotalDonationFromDB() {
        
    }
}

extension AZStoreKit: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        Log.debug("products: \(products)")
        /*
         localizedTitle: "Unlock full version"
         productIdentifier: "net.jsloop.APIZen.UnlockFullVersion"
         */
        self.products = products
        self.restorePurchases()
    }
}

/// To get notified about purchases and restores.
extension AZStoreKit: SKPaymentTransactionObserver {}

extension AZStoreKit: SKPaymentQueueDelegate {
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        Log.debug("Payment queue restore completed")
        // TODO: check for user defaults value
        // When there are no previous purchases, the updatedTransactions is not invoked.
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                if transaction.payment.productIdentifier == IAPID.unlockFullVersion {
                    Log.debug("Restored or purchased \(IAPID.unlockFullVersion)")
                    // TODO: set user defaults value
                }
            default:
                Log.debug("IAP state: \(transaction.transactionState) - ID: \(transaction.payment.productIdentifier)")
                break
            }
        }
    }
}
