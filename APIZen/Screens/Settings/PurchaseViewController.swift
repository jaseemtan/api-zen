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
    @IBOutlet weak var circuitBoard: UIImageView!
    
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
            var computedHeight = height - (36 + 44 + 24 + 44 + 24 + 120)
            if UI.getDeviceType() == .pad {
                if UI.getCurrentDeviceOrientation() == .landscapeLeft || UI.getCurrentDeviceOrientation() == .landscapeRight {
                    circuitBoard.image = UIImage(named: "circuit-board-ipad-landscape")
                    computedHeight = computedHeight - (200 + 80)  // 200 image size; 80 safe area height adjustment
                } else {
                    circuitBoard.image = UIImage(named: "circuit-board-ipad-portrait")
                    computedHeight = computedHeight - (310 + 80)
                }
            } else {  // phone
                if UI.getCurrentDeviceOrientation() == .landscapeLeft || UI.getCurrentDeviceOrientation() == .landscapeRight {
                    circuitBoard.image = UIImage(named: "circuit-board-landscape")
                    computedHeight = computedHeight - (200 + 125)
                } else {
                    circuitBoard.image = UIImage(named: "circuit-board-portrait")
                    if UI.hasNotch() {
                        computedHeight = computedHeight - (200 + 115)  // On phone, we don't need to add additional space. We need to reduce it to so that it aligns beaufifully with the bottom and looks like it's growing.
                    } else {
                        computedHeight = computedHeight - (200 + 70)  // On devices with home button
                    }
                }
            }
            return computedHeight < 50 ? 50 : computedHeight
        case CellId.circuitImage.rawValue:
            if UI.getDeviceType() == .pad {
                if UI.getCurrentDeviceOrientation() == .landscapeLeft || UI.getCurrentDeviceOrientation() == .landscapeRight {
                    return 225
                }
                return 315
            }
            if UI.getCurrentDeviceOrientation() == .landscapeLeft || UI.getCurrentDeviceOrientation() == .landscapeRight {
                return 200
            }
            return 200
        default:
            break
        }
        return UITableView.automaticDimension
    }
}
