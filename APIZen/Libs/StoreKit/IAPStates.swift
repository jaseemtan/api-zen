//
//  IAPStates.swift
//  APIZen
//
//  Created by Jaseem V V on 12/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import GameplayKit

/// In this state all In-App products will be fetched from the App Store. This is the first state always.
class ProductsFetchState: GKState {
    
}

/// In this state all products purchased will be fetched and local state updated for each purchase of the product.
class RestoreAllIAPsState: GKState {
    
}

/// In this state a new In-App purchase will be made corresponding to the selected product.
class PurchaseIAPState: GKState {
    
}

/// This state is entered when after fetching all In-App purchases, the products are found to be cancelled and refunded.
class IAPCancelledAndRefundedState: GKState {
    
}

/// This is the introductory trial state where user can experience the full version of the app for limited period of time.
class IAPTrialState: GKState {
    
}

/// This is the state when trial gets expired and user continues the usage without purchasing the full version. It goes to free mode which has restrictions.
class FreeState: GKState {
    
}

/// This state is entered after user purchases the full version.
class UnlockedFullVersionState: GKState {
    
}
