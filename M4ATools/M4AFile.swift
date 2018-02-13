//
//  M4AFile.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 2/8/18.
//  Copyright © 2018 Andrew Hyatt. All rights reserved.
//

import Foundation

public class M4AFile {
    
    public class Block {
        
        let type: String
        let data: Data
        
        weak var parent: Block?
        
        var children = [Block]()
        
        init(type: String, data: Data, parent: Block?) {
            self.type = type
            self.data = data
            
            // Load child blocks
            // Only explore supported parent blocks for now
            if type == "moov" || type == "udta" || type == "meta" || type == "ilst" ||
                (parent != nil && parent!.type == "ilst") {
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
                    
                    let childBlock = Block(type: type, data: contents, parent: self)
                    children.append(childBlock)
                    
                    index = index.advanced(by: size)
                }
            }
        }
        
        func write(_ to: Data) -> Data {
            var outData = to
            var size = UInt32(calculateSize()).bigEndian
            let sizeData = Data(bytes: &size, count: MemoryLayout.size(ofValue: size))

            let typeData = type.data(using: .macOSRoman)!
            
            if type == "mdat" {
                outData.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            } else {
                outData.append(sizeData)
            }
            
            outData.append(typeData)
            
            if type == "meta" {
                outData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
            }
            
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
                var childSize = 8
                
                if type == "meta" {
                    childSize += 4
                }
                
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
    
    public enum Metadata {
        
        public enum StringMetadata : String {
            
            case album = "©alb"
            case artist = "©art"
            case albumArtist = "aART"
            case comment = "©cmt"
            case year = "©day"
            case title = "©nam"
            case genreCustom = "©gen"
            case composer = "©wrt"
            case encoder = "©too"
            case copyright = "cprt"
            case compilation = "cpil"
            case lyrics = "©lyr"
            case purchaseDate = "purd"
            
        }
        
        public enum IntMetadata : String {
            
            case genreID = "gnre"
            case track = "trkn"
            case disk = "disk"
            case bpm = "tmpo"
            case rating = "rtng"
            case gapless = "pgap"
            
        }
        
        public enum ImageMetadata: String {
            
            case artwork = "covr"
            
        }
        
    }
    
    private static let validTypes = ["ftyp", "mdat", "moov", "pnot", "udta", "uuid", "moof", "free",
                                     "skip", "jP2 ", "wide", "load", "ctab", "imap", "matt", "kmat", "clip",
                                     "crgn", "sync", "chap", "tmcd", "scpt", "ssrc", "PICT"]
    
    public var blocks: [Block]
    
    public var metadataBlock: Block? {
        return findBlock(["moov", "udta", "meta", "ilst"])
    }
    
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
            
            let type = String(data: typeData, encoding: .macOSRoman)!
            
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
            
            index = index.advanced(by: size)
            
            blocks.append(Block(type: type, data: blockContents, parent: nil))
        }
    }
    
    public func write(url: URL) throws {
        var data = Data()
        for block in blocks {
            data = block.write(data)
        }
        
        try data.write(to: url)
    }
    
    public func getStringMetadata(_ metadata: Metadata.StringMetadata) -> String? {
        guard let metadataContainerBlock = self.metadataBlock else {
            return nil
        }
        
        let type = metadata.rawValue
        
        guard let metaBlock = M4AFile.getMetadataBlock(metadataContainer: metadataContainerBlock, name: type) else {
                return nil
        }
        
        guard let data = M4AFile.readMetadata(metadata: metaBlock) else {
            return nil
        }
        
        return String(bytes: data, encoding: .utf8)
    }
    
    public func getIntMetadata(_ metadata: Metadata.IntMetadata) -> UInt8? {
        guard let metadataContainerBlock = self.metadataBlock else {
            return nil
        }
        
        let type = metadata.rawValue
        
        guard let metaBlock = M4AFile.getMetadataBlock(metadataContainer: metadataContainerBlock, name: type) else {
            return nil
        }
        
        guard let data = M4AFile.readMetadata(metadata: metaBlock), data.count == 2 else {
            return nil
        }
        
        return UInt8(data[1])
    }
    
    public func setStringMetadata(_ metadata: Metadata.StringMetadata, value: String) {
        
    }
    
    public func setIntMetadata(_ metadata: Metadata.IntMetadata, value: UInt8) {
        
    }
    
    private static func getMetadataBlock(metadataContainer: Block, name: String) -> Block? {
        for block in metadataContainer.children {
            if block.type == name {
                return block
            }
        }
        return nil
    }
    
    private static func readMetadata(metadata: Block) -> Data? {
        var data = metadata.data
        let sizeData = data[data.startIndex ..< data.startIndex.advanced(by: 4)]
        let typeData = data[data.startIndex.advanced(by: 4) ..< data.startIndex.advanced(by: 8)]
        let shouldBeNullData = data[data.startIndex.advanced(by: 8) ..< data.startIndex.advanced(by: 16)]
        data = data.advanced(by: sizeData.count + typeData.count + shouldBeNullData.count)
        
        let size = Int(UInt32(bigEndian: sizeData.withUnsafeBytes { $0.pointee }))
        guard let type = String(bytes: typeData, encoding: .macOSRoman), type == "data" else {
            return nil
        }
        
        guard shouldBeNullData.elementsEqual([0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]) ||
            shouldBeNullData.elementsEqual([0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x00]) else {
            return nil
        }
        
        guard size == shouldBeNullData.count + typeData.count + sizeData.count + data.count else {
            return nil
        }
        
        return data
    }
    
    public func findBlock(_ pathComponents: [String]) -> Block? {
        assert(!pathComponents.isEmpty)
        
        var blocks = self.blocks
        for component in pathComponents {
            if let block = M4AFile.getBlockOneLevel(blocks: blocks, type: component) {
                if component == pathComponents.last! {
                    return block
                } else {
                    blocks = block.children
                }
            } else {
                return nil
            }
        }
        return nil
    }
    
    private static func getBlockOneLevel(blocks: [Block], type: String) -> Block? {
        for block in blocks {
            if block.type == type {
                return block
            }
        }
        return nil
    }
    
    private func typeIsValid(_ type: String) -> Bool {
        return M4AFile.validTypes.contains(type)
    }
}
