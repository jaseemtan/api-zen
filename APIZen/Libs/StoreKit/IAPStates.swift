//
//  IAPStates.swift
//  APIZen
//
//  Created by Jaseem V V on 12/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import GameplayKit

/// Display the total amount donated in the UI. This value will be retrieved from user's iCloud DB.
class DonationAmountDisplayState: GKState {
    
}

/// In this state all In-App products will be fetched from the App Store.
class ProductsFetchState: GKState {
    
}

/// Thanks IAP donation.
class DonateLowState: GKState {
    
}

/// Thank you IAP donation.
class DonateMediumState: GKState {
    
}

/// Thank you very much IAP donation.
class DonateHighState: GKState {
    
}
