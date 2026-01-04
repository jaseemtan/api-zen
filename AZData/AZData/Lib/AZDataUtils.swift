//
//  AZDataUtils.swift
//  APIZen
//
//  Created by Jaseem V V on 27/01/24.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData
import AZCommon

/// Helper methods to work with CoreData 
public class AZDataUtils {
    public static let shared = AZDataUtils()
    private let utils = AZUtils.shared
    
    /// Copies all attribute values from the source object to destination object for the attributes in destination object
    public func copyAttributeValues(src: NSManagedObject, dest: NSManagedObject) -> NSManagedObject {
        let srcAttribKeys = Array(src.entity.attributesByName.keys)
        let srcAttribValues = src.dictionaryWithValues(forKeys: srcAttribKeys)
        let destAttribKeys = Array(dest.entity.attributesByName.keys)
        for key in destAttribKeys {
            dest.setValue(srcAttribValues[key], forKey: key)
        }
        return dest
    }
    
    public func saveSelectedWorkspaceId(_ id: String) {
        self.utils.setValue(key: AZConst.selectedWorkspaceIdKey, value: id)
    }
    
    public func saveSelectedWorkspaceContainer(_ container: CoreDataContainer) {
        self.utils.setValue(key: AZConst.selectedWorkspaceContainerKey, value: container.rawValue)
    }
}
