//
//  AZLogger.swift
//  APIZen
//
//  Created by Jaseem V V on 03/12/23.
//  Copyright © 2023 Jaseem V V. All rights reserved.
//

import Foundation

@objc
public class Log: NSObject {
    @objc
    public static func debug(_ msg: Any) {
        #if DEBUG
        print("[DEBUG] \(msg)")
        #endif
    }
    
    @objc
    public static func error(_ msg: Any) {
        print("[ERROR] \(msg)")
    }

    @objc
    public static func info(_ msg: Any) {
        print("[INFO] \(msg)")
    }
}
