//
//  ThemeManager.swift
//  APIZenMac
//
//  Created by Jaseem V V on 09/12/25.
//

import SwiftUI
import AZData

/// Handles colours and themeing.
class ThemeManager {
    static let shared = ThemeManager()
    
    /// Returns the system accent colour.
    func getAccentColor() -> Color {
        return Color.accentColor
    }
    
    /// The description text colour.
    func getDescriptionColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .darkGrey4 : .lightGrey4
    }
    
    /// Foreground style for elements like images which returns the system accent colour.
    func getForegroundStyle() -> Color {
        return Color(nsColor: .controlAccentColor)
    }
    
    /// Returns workspace type icon name which can be used in image view. Mac or iCloud.
    func getWorkspaceTypeIconName(coreDataContainer: CoreDataContainer) -> String {
        return coreDataContainer == .local ? "desktopcomputer" : "icloud"
    }
    
    func getSortIconName() -> String {
        return "line.3.horizontal.decrease.circle"
    }
}

/// API Zen color values for macOS
extension Color {
    static let darkGrey  = Color(NSColor(red: 39/255,  green: 40/255,  blue: 42/255,  alpha: 1.0))
    static let darkGrey1 = Color(NSColor(red: 50/255,  green: 50/255,  blue: 50/255,  alpha: 1.0))
    static let darkGrey2 = Color(NSColor(red: 70/255,  green: 70/255,  blue: 70/255,  alpha: 1.0))
    static let darkGrey3 = Color(NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0))
    static let darkGrey4 = Color(NSColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1.0))

    static let lightGrey  = Color(NSColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0))
    static let lightGrey1 = Color(NSColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0))
    static let lightGrey2 = Color(NSColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 1.0))
    static let lightGrey3 = Color(NSColor(red: 175/255, green: 175/255, blue: 175/255, alpha: 1.0))
    static let lightGrey4 = Color(NSColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1.0))
    static let lightGrey5 = Color(NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0))

    static let lightPurple = Color(NSColor(red: 119/255, green: 123/255, blue: 246/255, alpha: 1.0))
}
