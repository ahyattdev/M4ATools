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
            _ = try M4AFile(url: url!)
        } catch {
            XCTFail()
        }
    }
    
    func testWriteFile() {
        let outURL = URL(fileURLWithPath: "/tmp/foo.m4a")
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")

        do {
            let audio = try M4AFile(url: url!)
            try audio.write(url: outURL)
        } catch {
            XCTFail()
        }
    }
    
    func testReadMetadata() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")
        XCTAssertNotNil(url)
        
        do {
            let audio = try M4AFile(url: url!)
            
            XCTAssert(audio.getStringMetadata(.album) == "Album")
            XCTAssert(audio.getIntMetadata(.bpm) == 120)
            
            let otherURL = bundle.url(forResource: "sample-meta2",
                                      withExtension: "m4a")!
            
            _ = try M4AFile(url: otherURL)
            
        } catch {
            XCTFail()
        }
    }
    
    func testWriteMetadata() {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "sample-metadata", withExtension: "m4a")!
        
        let out = URL(fileURLWithPath: "/tmp/writetest.m4a")
        
        do {
            var m4a = try M4AFile(url: url)
            m4a.setStringMetadata(.sortingArtist, value: "Arty Artist")
            m4a.setIntMetadata(.gapless, value: 1)
            try m4a.write(url: out)
            
            m4a = try M4AFile(url: out)
            XCTAssert(m4a.getIntMetadata(.gapless) == 1)
            XCTAssert(m4a.getStringMetadata(.sortingArtist) == "Arty Artist")
        } catch {
            XCTFail()
        }
    }
    
}
