//
//  AZStoreKit.swift
//  APIZen
//
//  Created by Jaseem V V on 01/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
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
    public typealias ProductFetchedHandler = ([SKProduct]) -> Void
    public typealias PurchaseHandler = () -> Void
    var productFetchedHandler: ProductFetchedHandler? = nil
    var purchaseHandler: PurchaseHandler? = nil
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    /// Retrieves the list of In-App products from the App Store.
    public func getListOfInAppProducts(_ completion: ProductFetchedHandler? = nil) {
        self.productFetchedHandler = completion
        let productRequest = SKProductsRequest(productIdentifiers: self.productIds)
        productRequest.delegate = self
        productRequest.start()
    }
    
    public func getDonationLowTier() -> SKProduct? {
        if self.products.isEmpty { return nil }
        return self.products.first { product in
            product.productIdentifier == IAPID.thanks
        }
    }
    
    public func getDonationMediumTier() -> SKProduct? {
        if self.products.isEmpty { return nil }
        return self.products.first { product in
            product.productIdentifier == IAPID.thankYou
        }
    }
    
    public func getDonationHighTier() -> SKProduct? {
        if self.products.isEmpty { return nil }
        return self.products.first { product in
            product.productIdentifier == IAPID.thankYouVeryMuch
        }
    }
    
    public func getProductForIdentifier(_ id: String) -> SKProduct? {
        if self.products.isEmpty { return nil }
        return self.products.first { product in
            product.productIdentifier == id
        }
    }
    
    /// Make a purchase of the given In-App product
    public func makePurchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func makeDonationLowTier(_ completion: PurchaseHandler? = nil) {
        if self.products.isEmpty { return }
        if let product = self.getDonationLowTier() {
            self.purchaseHandler = completion
            self.makePurchase(product: product)
        }
    }
    
    public func makeDonationMediumTier(_ completion: PurchaseHandler? = nil) {
        if self.products.isEmpty { return }
        if let product = self.getDonationMediumTier() {
            self.purchaseHandler = completion
            self.makePurchase(product: product)
        }
    }
    
    public func makeDonationHighTier(_ completion: PurchaseHandler? = nil) {
        if self.products.isEmpty { return }
        if let product = self.getDonationHighTier() {
            self.purchaseHandler = completion
            self.makePurchase(product: product)
        }
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // NB: **New model version Core Data**
    
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
        #if DEBUG
        products.forEach { product in
            Log.debug(product.productIdentifier)
        }
        #endif
        self.products = products
        if let completion = self.productFetchedHandler {
            completion(self.products)
        }
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
                Log.debug("Donated successfully")
                SKPaymentQueue.default().finishTransaction(transaction)
                if let product = self.getProductForIdentifier(transaction.payment.productIdentifier) {
                    Log.debug("Donated \(product.productIdentifier) for \(product.priceLocale.currencySymbol ?? "")\(product.price)")
                    // TODO: save to DB and display in UI
                }
                if let completion = self.purchaseHandler {
                    completion()
                }
            case .failed:
                Log.error("Error donating")
                SKPaymentQueue.default().finishTransaction(transaction)
                if let completion = self.purchaseHandler {
                    completion()
                }
            default:
                Log.debug("IAP state: \(transaction.transactionState) - ID: \(transaction.payment.productIdentifier)")
                if let completion = self.purchaseHandler {
                    completion()
                }
                break
            }
        }
    }
}
