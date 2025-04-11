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
    public static let unlockFullVersion = "net.jsloop.APIZen.UnlockFullVersion"
}

public class AZStoreKit: NSObject {
    public static let shared = AZStoreKit()
    let productIds: Set<String> = [IAPID.unlockFullVersion]
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
    
    public func getUnlockFullVersionProduct() -> SKProduct? {
        if self.products.isEmpty { return nil }
        return self.products.first { product in
            product.productIdentifier == IAPID.unlockFullVersion
        }
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
