//
//  AppRuntime.swift
//  AZCommon
//
//  Created by Jaseem V V on 13/12/25.
//

import Foundation

enum AppRuntime {
    /// Check if the app is in testing mode.
    static var isTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-AZ_TESTING")
    }
}
