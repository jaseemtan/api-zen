//
//  ThreeColumnSplitView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI
import AppKit
import AZCommon

/// Three column split view backed by NSSplitViewController. This controller is used so that the pane position is maintained across window launches automatically.
/// SwiftUI currently does not have this functionality. Doing a manual implementation causes jitter during pane dragging.
/// This struct takes three SwiftUI views and visibility flags for left pane and right pane.
struct ThreeColumnSplitView<Left: View, Center: View, Right: View>: NSViewControllerRepresentable {
    let left: Left
    let center: Center
    let right: Right
    
    @Binding var showNavigator: Bool
    @Binding var showInspector: Bool

    class Coordinator {
        var leftHost: NSHostingController<Left>?
        var centerHost: NSHostingController<Center>?
        var rightHost: NSHostingController<Right>?
        
        init() {}
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeNSViewController(context: Context) -> NSSplitViewController {
        let splitVC = NSSplitViewController()
        
        let leftHosting = NSHostingController(rootView: left)
        let leftItem = NSSplitViewItem(viewController: leftHosting)
        leftItem.minimumThickness = 180
        leftItem.maximumThickness = 400
        context.coordinator.leftHost = leftHosting
        
        let centerHosting = NSHostingController(rootView: center)
        let centerItem = NSSplitViewItem(viewController: centerHosting)
        context.coordinator.centerHost = centerHosting
        
        let rightHosting = NSHostingController(rootView: right)
        let rightItem = NSSplitViewItem(viewController: rightHosting)
        rightItem.minimumThickness = 180
        rightItem.maximumThickness = 400
        context.coordinator.rightHost = rightHosting
        
        splitVC.addSplitViewItem(leftItem)
        splitVC.addSplitViewItem(centerItem)
        splitVC.addSplitViewItem(rightItem)
        
        splitVC.splitView.isVertical = true
        splitVC.splitView.autosaveName = "az-three-colum-split-view"
        
        return splitVC
    }
    
    func updateNSViewController(_ nsViewController: NSSplitViewController, context: Context) {
        Log.debug("update ns view controller - split vc")
        DispatchQueue.main.async {
            // Update the rootView of hosting controllers so SwiftUI body gets refreshed
            if let leftHost = context.coordinator.leftHost {
                leftHost.rootView = self.left
            }
            if let centerHost = context.coordinator.centerHost {
                centerHost.rootView = self.center
            }
            if let rightHost = context.coordinator.rightHost {
                rightHost.rootView = self.right
            }
            // Should hide navigator?
            let hideNav = !self.showNavigator
            if let leftItem = nsViewController.splitViewItems.first, leftItem.isCollapsed != hideNav {
                leftItem.isCollapsed = hideNav
            }
            // Should hide inspector?
            let hideInspector = !self.showInspector
            if let rightItem = nsViewController.splitViewItems.last, rightItem.isCollapsed != hideInspector {
                rightItem.isCollapsed = hideInspector
            }
        }
    }
}
