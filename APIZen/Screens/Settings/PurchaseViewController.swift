//
//  DonateViewController.swift
//  APIZen
//
//  Created by Jaseem V V on 01/04/25.
//  Copyright © 2025 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import AZCommon

class DonateTableViewController: APITesterProTableViewController {
    @IBOutlet weak var circuitBoard: UIImageView!
    @IBOutlet weak var donationAmountLabel: UILabel!
    @IBOutlet weak var thanksBtn: UIButton!
    @IBOutlet weak var thankYouBtn: UIButton!
    @IBOutlet weak var thankYouVeryMuchBtn: UIButton!
    private let app = App.shared
    private let azsk = AZStoreKit.shared
    private var barBtn: UIButton!
    private var indicatorView: UIView?
    
    enum CellId: Int {
        case spacerAfterTop
        case donationAmount
        case spacerAfterDonationAmount
        case thanks
        case spacerAfterThanks
        case thankYou
        case spacerAfterThankYou
        case thankYouVeryMuch
        case noteToUser
        case spacerAfterNoteToUser
        case circuitImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("purchase tvc did load")
        self.initUI()
    }
    
    override func initUI() {
        super.initUI()
        self.app.updateViewBackground(self.view)
        self.app.updateNavigationControllerBackground(self.navigationController)
        self.tableView.backgroundColor = App.Color.tableViewBg
        self.navigationItem.title = "Donation"
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        self.addNavigationBarRestoreButton()
        self.thanksBtn.isEnabled = false
        DispatchQueue.main.async {
            // TODO: display loading based on AZStoreKit state
            self.showLoadingIndicator()
        }
    }
    
    func addNavigationBarRestoreButton() {
        self.barBtn = UIButton(type: .custom)
        self.barBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.barBtn.setTitleColor(self.barBtn.tintColor, for: .normal)
        self.barBtn.addTarget(self, action: #selector(self.restoreBarButtonDidTap(_:)), for: .touchUpInside)
        self.barBtn.setTitle("Restore", for: .normal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.barBtn)
    }
    
    func showLoadingIndicator() {
        if self.indicatorView == nil { self.indicatorView = UIView() }
        UI.showCustomActivityIndicator(self.indicatorView!, mainView: self.view, shouldDisableInteraction: true)
    }
    
    func hideLoadingIndicator() {
        if let indicatorView = self.indicatorView {
            UI.removeCustomActivityIndicator(indicatorView)
            self.indicatorView = nil
        }
    }
    
    @objc func restoreBarButtonDidTap(_ sender: Any) {
        Log.debug("restore button did tap")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case CellId.spacerAfterTop.rawValue:
            return 36
        case CellId.donationAmount.rawValue:
            return 44
        case CellId.spacerAfterDonationAmount.rawValue:
            return 24
        case CellId.thanks.rawValue:
            return 44
        case CellId.spacerAfterThanks.rawValue:
            return 24
        case CellId.thankYou.rawValue:
            return 44
        case CellId.spacerAfterThankYou.rawValue:
            return 24
        case CellId.thankYouVeryMuch.rawValue:
            return 44
        case CellId.noteToUser.rawValue:
            return 44
        case CellId.spacerAfterNoteToUser.rawValue:  // TODO: test
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
