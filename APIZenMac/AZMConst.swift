//
//  AZMConst.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import Foundation

/// Constants specific to macOS.
struct AZMConst {
    // MARK: - User default keys
    public static let workspacePopupWindowStateKey = "workspacePopupWindowState"
    public static let projectsListStateKey = "projectsListState"
    // MARK: - Misc
}

enum AppRuntime {
    static var isTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-AZ_TESTING")
    }
}
