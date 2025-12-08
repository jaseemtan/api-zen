//
//  AZEnvironment.swift
//  APIZenMac
//
//  Created by Jaseem V V on 08/12/25.
//

import SwiftUI
import CoreData
import AZData

/// Provides the option to set coreDataContainer enum to environment.
private struct CoreDataContainerKey: EnvironmentKey {
    static let defaultValue: Binding<CoreDataContainer> = .constant(.local)
}

extension EnvironmentValues {
    var coreDataContainer: Binding<CoreDataContainer> {
        get { self[CoreDataContainerKey.self] }
        set { self[CoreDataContainerKey.self] = newValue }
    }
}
