//
//  AZStoreKit.swift
//  APIZen
//
//  Created by Jaseem V V on 01/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import StoreKit
import AZCommon
import AZData

public struct IAPID {
    /// Consumables
    public static let thanks = "net.jsloop.APIZen.Thanks"
    public static let thankYou = "net.jsloop.APIZen.Thankyou"
    public static let thankYouVeryMuch = "net.jsloop.APIZen.Thankyouverymuch"
    
    public static func getTier(_ productId: String) -> Int64 {
        switch productId {
        case IAPID.thanks:
            return 1
        case IAPID.thankYou:
            return 2
        case IAPID.thankYouVeryMuch:
            return 3
        default:
            return 2
        }
    }
}

public class AZStoreKit: NSObject {
    public static let shared = AZStoreKit()
    let productIds: Set<String> = [IAPID.thanks, IAPID.thankYou, IAPID.thankYouVeryMuch]
    var products: [SKProduct] = []
    public typealias ProductFetchedHandler = ([SKProduct]) -> Void
    public typealias PurchaseHandler = () -> Void
    var productFetchedHandler: ProductFetchedHandler? = nil
    var purchaseHandler: PurchaseHandler? = nil
    private lazy var db = { CoreDataService.shared }()
    private let nc = NotificationCenter.default
    
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
    
    public func getDisplayPriceForProduct(_ product: SKProduct, iAPId: String) -> String {
        return "\(product.priceLocale.currencySymbol ?? "") \(product.price)"
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

    
    /// Backup data for storing user's total donations
    public func saveTotalDonationAmountToCloudKitKVStore() {
        // todo:
    }
    
    /// Backup data retrieving user's total donations. The value from CloudKit Core Data store takes precedence in case of a mismatch.
    public func getTotalDonationAmountFromCloudKitKVStore() {
        // todo:
    }
    
    public func saveDonationToDB(_ product: SKProduct) {
        // donation amount - decimal (for regions other than US with price adjustment)
        // currency - name, symbol
        // date - day, month, year, time
        // Device meta that made the purchase
        let productId = product.productIdentifier
        let price = product.price
        let currencySymbol = product.priceLocale.currencySymbol
        var currency = ""
        if #available(iOS 16, *) {
            currency = product.priceLocale.currency?.identifier ?? ""
        } else {
            currency = ""
        }
        if let donation = self.db.createDonation(ctx: self.db.ckMainMOC) {
            donation.amount = price
            donation.currency = currency
            donation.currencySymbol = currencySymbol
            donation.deviceName = UIDevice.current.name
            donation.iapId = productId
            donation.model = UIDevice.current.model
            donation.systemName = UIDevice.current.systemName
            donation.systemVersion = UIDevice.current.systemVersion
            donation.tier = IAPID.getTier(productId)
            donation.vendorId = UIDevice.current.identifierForVendor
            donation.version = CoreDataService.modelVersion
            self.db.saveMainContext { _ in
                self.nc.post(name: .donationDidChange, object: self)
            }
        }
    }
    
    public func getDonationsFromDB() {
        let donations = self.db.getDonations()
        Log.debug("donations count: \(donations.count)")
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
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                Log.debug("Donated successfully")
                SKPaymentQueue.default().finishTransaction(transaction)
                if let product = self.getProductForIdentifier(transaction.payment.productIdentifier) {
                    Log.debug("Donated \(product.productIdentifier) for \(product.priceLocale.currencySymbol ?? "")\(product.price)")
                    self.saveDonationToDB(product)
                }
                if let completion = self.purchaseHandler {
                    completion()
                    self.purchaseHandler = nil
                }
            case .failed:
                Log.error("Error donating")
                SKPaymentQueue.default().finishTransaction(transaction)
                if let completion = self.purchaseHandler {
                    completion()
                    self.purchaseHandler = nil
                }
            case .purchasing:
                Log.debug("Purchasing")
                break
            case .deferred:
                Log.debug("Deferred")
                break
            @unknown default:
                Log.debug("IAP state: \(transaction.transactionState) - ID: \(transaction.payment.productIdentifier)")
                if let completion = self.purchaseHandler {
                    completion()
                    self.purchaseHandler = nil
                }
                break
            }
        }
    }
}
