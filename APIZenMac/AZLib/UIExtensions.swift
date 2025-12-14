//
//  UIExtensions.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI
import Cocoa
import ObjectiveC
import AZCommon

extension View {
    /// Adds a rectangular border around the given view so that the dimensions can be made visible. Helps in identifying button click area.
    /// This is useful mainly in debugging.
    func debugOverlay() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
    }
    
    /// Attach a tap handler only when `enabled` is true.
    /// This is handy when we want to have click on list view by default. But when drag mode is enabled, we remove the tap gesture to make drag to work.
    @ViewBuilder  // ViewBuilder is required so that the function can return different view trees.
    func onTapIf(_ enabled: Bool, perform action: @escaping () -> Void) -> some View {
        if enabled {
            self.onTapGesture(perform: action)
        } else {
            self
        }
    }
}

extension NSApplication {
    /// Open the given view in a new tab in the current window. This will open an AppKit window. This window behavious like AppKit native window.
    /// Which means the default new tab button available in a main window created by SwiftUI will not work.
    func openInNewTab<Content: View>(_ view: Content) {
        DispatchQueue.main.async {
            guard let mainWindow = NSApp.mainWindow ?? NSApp.windows.first else {
                Log.debug("No main window found")
                return
            }

            // Enable tabbing
            NSWindow.allowsAutomaticWindowTabbing = true
            mainWindow.tabbingMode = .preferred

            let newWindow = NSWindow(
                contentRect: mainWindow.frame,
                styleMask: [.titled, .resizable, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

            newWindow.tabbingMode = .preferred
            newWindow.isReleasedWhenClosed = false
            newWindow.contentView = NSHostingView(rootView: view)

            // Order first
            newWindow.orderFront(nil)

            // Add as tab
            mainWindow.addTabbedWindow(newWindow, ordered: .above)
        }
    }
}

private var windowIndexKey: UInt8 = 0

extension NSWindow {
    /// Allows us to associate a windowIndex for the SwiftUI window.
    var windowIndex: Int? {
        get {
            objc_getAssociatedObject(self, &windowIndexKey) as? Int
        }
        set {
            objc_setAssociatedObject(self, &windowIndexKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
