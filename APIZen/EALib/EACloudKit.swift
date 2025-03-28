//
//  EACloudKit.swift
//  APIZen
//
//  Created by Jaseem V V on 22/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CloudKit

/// A class to work with CloudKit. Enable iCloud capability with CloudKit container. This will also enable push notification which is used to notify app on DB changes by CloudKit.
class EACloudKit {
    static let shared = EACloudKit()
    private lazy var ckStore = { NSUbiquitousKeyValueStore.default }()
        
    deinit {}
    
    init() {}

    func bootstrap() {
        if isRunningTests { return }
    }

    // MARK: - KV Store
    
    func getValue(key: String) -> Any? {
        return self.ckStore.object(forKey: key)
    }
    
    func saveValue(key: String, value: Any) {
        self.ckStore.set(value, forKey: key)
    }
    
    func removeValue(key: String) {
        self.ckStore.removeObject(forKey: key)
    }
    
    // MARK: - iCloud
    
    /// Invokes the given callback with the iCloud account status.
    func accountStatus(completion: @escaping (Result<CKAccountStatus, Error>) -> Void) {
        CKContainer.default().accountStatus { status, error in
            if let err = error { completion(.failure(err)); return }
            completion(.success(status))
        }
    }
    
    /// Get iCloud account status async.
    func accountStatus() async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { continuation in
            self.accountStatus { result in
                switch (result) {
                case .success(let status):
                    continuation.resume(returning: status)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func isiCloudAvailable() async throws -> Bool {
        return try await self.accountStatus() == CKAccountStatus.available
    }
}
