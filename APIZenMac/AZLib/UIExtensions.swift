//
//  UIExtensions.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI

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

