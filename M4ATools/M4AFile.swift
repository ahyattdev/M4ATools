//
//  M4AFile.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 2/8/18.
//  Copyright © 2018 Andrew Hyatt. All rights reserved.
//

import Foundation

public class M4AFile {
    
    public struct Block {
        
        let type: String
        let data: Data
        
        var children = [Block]()
        
        init(type: String, data: Data) {
            self.type = type
            self.data = data
            
            // Load child blocks
            // Only explore supported parent blocks for now
            if type == "moov" || type == "udta" || type == "meta" || type == "ilst" {
                var index = data.startIndex
                
                if type == "meta" {
                    // The first 4 bytes of meta are empty
                    index = index.advanced(by: 4)
                }
                
                while index != data.endIndex {
                    let sizeData = data.subdata(in: index ..< index.advanced(by: 4))
                    let size = Int(UInt32(bigEndian: sizeData.withUnsafeBytes { $0.pointee }))
                    let typeData = data.subdata(in: index.advanced(by: 4) ..< index.advanced(by: 8))
                    let type = String(data: typeData, encoding: .macOSRoman)!
                    
                    let contents = data.subdata(in: index.advanced(by: 8) ..< index.advanced(by: size))
                    
                    children.append(Block(type: type, data: contents))
                    
                    index = index.advanced(by: size)
                }
            }
        }
        
        func write(_ to: Data) -> Data {
            var outData = to
            var size = UInt32(calculateSize()).bigEndian
            let sizeData = Data(bytes: &size, count: MemoryLayout.size(ofValue: size))
            print(type)
            print(type)
            let typeData = type.data(using: .macOSRoman)!
            
            if type == "meta" {
                size += 4
                outData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
            }
            
            if type == "mdat" {
                outData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            } else {
                outData.append(sizeData)
            }
            
            outData.append(typeData)
            if children.isEmpty {
                outData.append(data)
            } else {
                for childBlock in children {
                    outData = childBlock.write(outData)
                }
            }
            return outData
        }
        
        func calculateSize() -> Int {
            if children.isEmpty {
                return 8 + data.count
            } else {
                var childSize = 0
                for child in children {
                    childSize += child.calculateSize()
                }
                return childSize
            }
        }
        
    }
    
    public enum M4AFileError: Error {
        
        case invalidBlockType
        case invalidFile
        
    }
    
    public class Metadata {
        
        // 255 byte limit for all except lyrics!
        
        public enum MetadataType : String {
            
            case album = "©alb"
            case artist = "©art"
            case albumArtist = "aART"
            case comment = "©cmt"
            case year = "©day"
            case title = "©nam"
            case genreID = "gnre"
            case genreCustom = "©gen"
            case track = "trkn"
            case disk = "disk"
            case composer = "©wrt"
            case encoder = "©too"
            case bpm = "tmpo"
            case copyright = "cprt"
            case compilation = "cpil"
            case artwork = "covr"
            case rating = "rtng"
            case lyrics = "©lyr"
            case purchaseDate = "purd"
            case gapless = "pgap"
            
        }
        
        fileprivate var blocks: [Block]
        
        fileprivate init(_ data: Data) throws {
            blocks = [Block]()
            
            var index = data.startIndex
            while index != data.endIndex {
                let sizeData = data.subdata(in: index ..< index.advanced(by: 4))
                let size = Int(UInt32(bigEndian: sizeData.withUnsafeBytes { $0.pointee }))
                let typeData = data.subdata(in: index.advanced(by: 4) ..< index.advanced(by: 8))
                let type = String(data: typeData, encoding: .macOSRoman)!
                
                let contents = data.subdata(in: index.advanced(by: 8) ..< index.advanced(by: size))
                
                blocks.append(Block(type: type, data: contents))
                
                index = index.advanced(by: size)
            }
            
            print(blocks)
        }
        
        fileprivate func write() throws {

        }
    }
    
    private static let validTypes = ["ftyp", "mdat", "moov", "pnot", "udta", "uuid", "moof", "free",
                                     "skip", "jP2 ", "wide", "load", "ctab", "imap", "matt", "kmat", "clip",
                                     "crgn", "sync", "chap", "tmcd", "scpt", "ssrc", "PICT"]
    
    public var blocks: [Block]
    
    public var metadata: Metadata!
    
    public init(_ data: Data) throws {
        blocks = [Block]()
        
        guard data.count >= 8 else {
            throw M4AFileError.invalidFile
        }
        
        // Begin reading file
        var index = data.startIndex
        while (index != data.endIndex) {
            // Offset 0 to 4
            let sizeData = data.subdata(in: index ..< index.advanced(by: 4))
            // Offset 4 to 8
            let typeData = data.subdata(in: index.advanced(by: 4) ..< index.advanced(by: 8))
            
            // Turn size into an integer
            var size = Int(UInt32(bigEndian: sizeData.withUnsafeBytes { $0.pointee }))
            print(size)
            
            let type = String(data: typeData, encoding: .macOSRoman)!
            print(type)
            
            guard typeIsValid(type) else {
                throw M4AFileError.invalidBlockType
            }
            
            if size == 1 && type == "mdat" {
                // mdat sometimes has a size of 1 and it's size is 12 bytes into itself
                let mdatSizeData = data.subdata(in: index.advanced(by: 12) ..< index.advanced(by: 16))
                size = Int(UInt32(bigEndian: mdatSizeData.withUnsafeBytes { $0.pointee }))
            }
            
            // Load block
            let blockContents = data.subdata(in: index.advanced(by: 8) ..< index.advanced(by: size))
            print(blockContents.description)
            
            index = index.advanced(by: size)
            
            blocks.append(Block(type: type, data: blockContents))
            
            if type == "moov" {
                do {
                   // metadata = try Metadata(blockContents)
                }
                
            }
        }
        print()
    }
    
    public func write(url: URL) throws {
        var data = Data()
        for block in blocks {
            data = block.write(data)
        }
        
        try data.write(to: url)
    }
    
    private func typeIsValid(_ type: String) -> Bool {
        return M4AFile.validTypes.contains(type)
    }
    
}
