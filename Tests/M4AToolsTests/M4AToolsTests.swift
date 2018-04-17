import XCTest
@testable import M4ATools

/// M4ATools tests
class M4AToolsTests: XCTestCase {
    
    /// Loads a M4A file
    func testLoadFile() {
        do {
            _ = try M4AFile(data: AudioFiles.sampleMetadata)
        } catch {
            XCTFail()
        }
    }
    
    /// Loads and then writes a M4A file
    func testWriteFile() {
        let outURL = URL(fileURLWithPath: "/tmp/foo.m4a")

        do {
            let audio = try M4AFile(data: AudioFiles.sampleMetadata)
            try audio.write(url: outURL)
        } catch {
            XCTFail()
        }
    }
    
    /// Loads a M4A file and reads metadata
    func testReadMetadata() {
        do {
            let audio = try M4AFile(data: AudioFiles.sampleMetadata)
            
            XCTAssert(audio.getStringMetadata(.album) == "Album")
            XCTAssert(audio.getUInt16Metadata(.bpm) == 120)
            
            _ = try M4AFile(data: AudioFiles.sampleMetadata2)
        } catch {
            XCTFail()
        }
    }
    
    /// Loads a M4A file and writes metadata
    func testWriteMetadata() {
        do {
            var m4a = try M4AFile(data: AudioFiles.sampleMetadata)
            m4a.setStringMetadata(.sortingArtist, value: "Arty Artist")
            m4a.setUInt8Metadata(.gapless, value: 1)
            m4a.setTwoIntMetadata(.track, value: (3, 8))
            let data = m4a.write()
            
            m4a = try M4AFile(data: data)
            XCTAssert(m4a.getUInt8Metadata(.gapless) == 1)
            XCTAssert(m4a.getStringMetadata(.sortingArtist) == "Arty Artist")
            guard let track = m4a.getTwoIntMetadata(.track) else {
                XCTFail()
                return
            }
            XCTAssert(track == (3, 8))
        } catch {
            XCTFail()
        }
    }
    
    /// Loads an M4A file with a different structure, writes to it, and writes
    func testLoadModifyAndWrite() {
        do {
            let m4a = try M4AFile(data: AudioFiles.whiteNoise)
            _ = try m4a.write(url: URL(string: "file:///tmp/audio-orig.m4a")!)
            m4a.setTwoIntMetadata(.disc, value: (1, 2))
            m4a.setStringMetadata(.year, value: "2014-08-25T07:00:00Z")
            m4a.setStringMetadata(.albumArtist, value: "Andrew Hyatt")
            m4a.setStringMetadata(.copyright, value: "© Andrew Hyatt Recordz")
            m4a.setUInt8Metadata(.rating, value: 0b00000001)
            _ = try m4a.write(url: URL(string: "file:///tmp/audio1.m4a")!)
            m4a.setUInt8Metadata(.rating, value: 0b00000001)
            _ = try m4a.write(url: URL(string: "file:///tmp/audio1.m4a")!)
        } catch {
            XCTFail()
        }
    }
    
    func testLocalFile() {
        do {
            let m4a = try M4AFile(url: URL(fileURLWithPath: "/Users/andrewhyatt/Desktop/wontplay/test2/down under work name.m4a"))
            
        } catch {
            XCTFail()
        }
    }
    
    /// Used by `swift test`
    static var allTests = [
        ("Test Load File", testLoadFile),
        ("Test Write File", testWriteFile),
        ("Test Read Metadata", testReadMetadata),
        ("Test Write Metadata", testWriteMetadata),
        ("Test Local File", testLocalFile),
    ]
}
