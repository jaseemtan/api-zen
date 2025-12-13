//
//  APIZenMacApp.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI
import AZData
import AZCommon

@main
struct APIZenMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    private let windowRegistry: WindowRegistry = WindowRegistry.shared
    private let db: CoreDataService = CoreDataService.shared
    
    var body: some Scene {
        // Single scene: each window represents one workspace
        WindowGroup("", id: "workspace") {  // We give empty window group name so that it does not appear on the title bar. If this parameter is not given at all, it shows the app name.
            MainWindowRoot()
                .onAppear {
                    Log.debug("az window group: on appear")
                    // Make sure default workspace is created in local CoreData container.
                    _ = self.db.getDefaultWorkspace(ctx: self.db.localMainMOC)
                    self.windowRegistry.restoreOpenWindows()
                }
        }
    }
}
