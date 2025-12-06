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
    let db = CoreDataService.shared
    
    var body: some Scene {
        WindowGroup {
            WorkspaceWindowRoot(db: self.db)
        }
    }
}

