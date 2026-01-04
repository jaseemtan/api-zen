//
//  AZPhoneExtensions.swift
//  APIZen
//
//  Created by Jaseem V V on 23/01/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CryptoKit

public extension UIImage {
    /// Offset the image from left
    func imageWithLeftPadding(_ left: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        self.draw(in: CGRect(x: left, y: 0, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

public extension UITableView {
    func scrollToBottom(_ indexPath: IndexPath? = nil) {
        let idxPath = indexPath != nil ? indexPath! : IndexPath(row: self.numberOfRows(inSection: 0) - 1, section: 0)
        self.scrollToRow(at: idxPath, at: .bottom, animated: true)
    }
    
    func scrollToBottom(section: Int? = 0) {
        let sec = section != nil ? section! : 0
        let idxPath = IndexPath(row: self.numberOfRows(inSection: sec) - 1, section: sec)
        self.scrollToRow(at: idxPath, at: .bottom, animated: true)
    }
}

public extension UILabel {
    /// Set the text to empty string.
    func clear() {
        self.text = ""
    }
}

/// Determine if view should be popped on navigation bar's back button tap
public protocol UINavigationBarBackButtonHandler {
    /// Should block the back button action
    func shouldPopOnBackButton() -> Bool
}

/// To not block the back button action by default
extension UIViewController: UINavigationBarBackButtonHandler {
    @objc open func shouldPopOnBackButton() -> Bool { return true }
}

extension UINavigationController: @retroactive UIBarPositioningDelegate {}
extension UINavigationController: @retroactive UINavigationBarDelegate {
    /// Check if current view controller should be popped on tapping the navigation bar back button.
    @objc public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        guard let items = navigationBar.items else { return false }
        
        if self.viewControllers.count < items.count { return true }
        
        var shouldPop = true
        if let vc = topViewController, vc.responds(to: #selector(UIViewController.shouldPopOnBackButton)) {
            shouldPop = vc.shouldPopOnBackButton()
        }
        
        if shouldPop {
            DispatchQueue.main.async { self.popViewController(animated: true) }
        } else {
            for aView in navigationBar.subviews {
                if aView.alpha > 0 && aView.alpha < 1 { aView.alpha = 1.0 }
            }
        }
        
        return false
    }
}

public extension UIViewController {
    var isNavigatedBack: Bool { !self.isBeingPresented && !self.isMovingToParent }
    var className: String { NSStringFromClass(self.classForCoder).components(separatedBy: ".").last! }
}
