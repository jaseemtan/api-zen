//
//  PurchaseViewController.swift
//  APIZen
//
//  Created by Jaseem V V on 01/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import AZCommon

class PurchaseTableViewController: UITableViewController {
    enum CellId: Int {
        case spacerAfterTop
        case purchaseStatus
        case spacerAfterPurchaseStatus
        case unlockFullVersionButton
        case spacerAfterUnlockFullVersionButton
        case trialMessage
        case freeMessage
        case fullVersionMessage
        case spaceAfterFullVersionMessage
        case circuitImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("purchase tvc did load")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case CellId.spacerAfterTop.rawValue:
            return 36
        case CellId.purchaseStatus.rawValue:
            return 44
        case CellId.spacerAfterPurchaseStatus.rawValue:
            return 24
        case CellId.unlockFullVersionButton.rawValue:
            return 44
        case CellId.spacerAfterUnlockFullVersionButton.rawValue:
            return 24
        case CellId.trialMessage.rawValue:
            return 120  // TODO: get dynamic value
        case CellId.freeMessage.rawValue:
            return 0
        case CellId.fullVersionMessage.rawValue:
            return 0
        case CellId.spaceAfterFullVersionMessage.rawValue:
            let height = UIScreen.main.bounds.height
            let computedHeight = height - (36 + 44 + 24 + 44 + 24 + 120 + 200 + 100)
            return computedHeight < 50 ? 50 : computedHeight
        case CellId.circuitImage.rawValue:
            return 200
        default:
            break
        }
        return UITableView.automaticDimension
    }
}
