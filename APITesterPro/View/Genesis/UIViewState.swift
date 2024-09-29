//
//  UIViewState.swift
//  APITesterPro
//
//  Created by Jaseem V V on 29.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI

/// Class that holds user interface display state.
@available(iOS 17.0, *)
class UIViewState {
    static let shared = UIViewState()
    private let utils = EAUtils.shared
    var accentColor: Color = .blue  // #007AFF
    var tintColor: Color = .blue
    private let accentColorKey = "accentColor"
    private let tintColorKey = "tintColor"
    
    struct Theme {
        static let darkGrey = UIColor(red: 39/255, green: 40/255, blue: 42/255, alpha: 1.0)
        static let lightGrey = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        static let lightGrey1 = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0)
    }
    
    init() {
        // self.saveUIColorToUserDefaults(.green)
        self.getUIColorFromUserDefaults()
    }
    
    // MARK: - UI Colour
    
    func getUIColorFromUserDefaults() {
        if let color = self.utils.getValue(accentColorKey) as? String {
            self.accentColor = Color(hex: color) ?? .blue
        }
        if let color = self.utils.getValue(tintColorKey) as? String {
            self.tintColor = Color(hex: color) ?? .blue
        }
    }
    
    func saveUIColorToUserDefaults(_ color: Color) {
        self.accentColor = color
        self.tintColor = color
        self.utils.setValue(key: accentColorKey, value: color.toHex())
        self.utils.setValue(key: tintColorKey, value: color.toHex())
    }
    
    func getActiveColor() -> Color {
        return self.accentColor
    }
    
    func getDisabledColor() -> Color {
        return Color.gray
    }
    
    func getTextFieldBg() -> Color {
        let color = UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return Theme.darkGrey
            } else {
                return Theme.lightGrey1
            }
        }
        return Color(color)
    }
    
    func getBottomToolbarBg() -> Color {
        return Color(Theme.lightGrey)
    }
}
