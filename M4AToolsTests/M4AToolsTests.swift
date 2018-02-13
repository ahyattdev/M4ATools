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
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")
        XCTAssertNotNil(url)

        do {
            let data = try Data(contentsOf: url!)
            _ = try M4AFile(data)
        } catch {
            XCTFail()
        }
    }
    
    func testWriteFile() {
        let outURL = URL(fileURLWithPath: "/tmp/foo.m4a")
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")

        do {
            let data = try Data(contentsOf: url!)
            let audio = try M4AFile(data)
            try audio.write(url: outURL)
        } catch {
            XCTFail()
        }
    }
    
    func testReadAlbumTitle() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")
        XCTAssertNotNil(url)
        
        do {
            let data = try Data(contentsOf: url!)
            let audio = try M4AFile(data)
            
            XCTAssert(audio.getStringMetadata(.album) == "Album")
        } catch {
            XCTFail()
        }
    }
    
}
