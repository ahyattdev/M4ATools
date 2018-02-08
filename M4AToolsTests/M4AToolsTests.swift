//
//  M4AToolsTests.swift
//  M4AToolsTests
//
//  Created by Andrew Hyatt on 2/8/18.
//  Copyright © 2018 Andrew Hyatt. All rights reserved.
//

import XCTest
import Foundation

@testable import M4ATools

class M4AToolsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoadFile() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample", withExtension: "m4a")
        XCTAssertNotNil(url)

        do {
            let data = try Data(contentsOf: url!)
            let audio = try M4AFile(data)
        } catch {
            XCTFail()
        }
    }
    
}
