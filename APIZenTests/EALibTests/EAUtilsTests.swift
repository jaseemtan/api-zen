//
//  EAUtilsTests.swift
//  APIZenTests
//
//  Created by Jaseem V V on 29/03/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import XCTest
import Foundation
import AZCommon
@testable import APIZen

class EAUtilsTests: XCTestCase {
    private let utils = AZUtils.shared
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    } 
    
    func testGenRandom() {
        let x = self.utils.genRandomString()
        XCTAssertEqual(x.count, 22)
    }
    
    func testUUIDCompressDecompress() {
        let uuid = UUID()
        let comp = self.utils.compress(uuid: uuid)
        let decomp = self.utils.decompress(shortId: comp)
        XCTAssertEqual(decomp, uuid.uuidString)
    }
    
    func testSysInfo() {
        let mem: Float = EASystem.memoryFootprint() ?? 0.0
        Log.debug("mem: \(mem / 1024 / 1024)")
        Log.debug("phy mem: \(EASystem.totalMemory())")
        Log.debug("active cpu: \(EASystem.activeProcessorCount())")
        Log.debug("total cpu: \(EASystem.processorCount())")
        XCTAssertTrue(mem > 0.0)
    }
}
