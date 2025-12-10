//
//  APIZenMacApp.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI
import AZData

@main
struct APIZenMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    var body: some Scene {
        // Single scene: each window represents one workspace
        WindowGroup("", id: "workspace") {  // We give empty window group name so that it does not appear on the title bar. If this parameter is not given at all, it shows the app name.
            MainWindowRoot()
        }
    }
}
