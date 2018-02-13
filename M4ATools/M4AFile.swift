//
//  M4AFile.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 2/8/18.
//  Copyright © 2018 Andrew Hyatt. All rights reserved.
//

import Foundation

/// Editable representation of a M4A audio file
///
/// - Author: Andrew Hyatt <ahyattdev@icloud.com>
/// - Copyright: Copyright © 2018 Andrew Hyatt
public class M4AFile {
    
    /// Utility byte arrays
    private struct ByteBlocks {
        
        /// Not needed
        private init() { }
        
        /// Four null bytes
        static let fourEmptyBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        
        /// A big endian 32-bit integer representing one
        static let fourByteOne: [UInt8] = [0x00, 0x00, 0x00, 0x01]
        
        /// Identifies `String` metadata
        static let stringIdentifier: [UInt8] = [0x00, 0x00, 0x00, 0x01, 0x00,
                                                0x00, 0x00, 0x00]
        
        /// Identifies `UInt8` metadata
        static let intIdentifier: [UInt8] = [0x00, 0x00, 0x00, 0x15, 0x00, 0x00,
                                             0x00, 0x00]
        
    }
    
    /// Represents a block within an M4A file
    ///
    /// - Note: Often nested within other blocks
    internal class Block {
        
        /// The block type
        let type: String
        /// The data of the block
        /// - note: Is only written on a write call if there are no children
        var data: Data
        
        /// The parent block, if the block has one
        weak var parent: Block?
        
        /// Children blocks, may be empty
        var children = [Block]()
        
        /// Initializes a block
        ///
        /// - parameters:
        ///   - type: The block type
        ///   - data: The data of the block. Excludes the size and type data.
        init(type: String, data: Data, parent: Block?) {
            self.type = type
            self.data = data
            
            // Load child blocks
            // Only explore supported parent blocks for now
            if type == "moov" || type == "udta" || type == "meta" ||
                type == "ilst" ||
                (parent != nil && parent!.type == "ilst") {
                var index = data.startIndex
                
                if type == "meta" {
                    // The first 4 bytes of meta are empty
                    index = index.advanced(by: 4)
                }
                
                while index != data.endIndex {
                    let sizeData = data.subdata(in: index
                        ..< index.advanced(by: 4))
                    let size = Int(UInt32(bigEndian:
                        sizeData.withUnsafeBytes { $0.pointee }))
                    let typeData = data.subdata(in: index.advanced(by: 4)
                        ..< index.advanced(by: 8))
                    let type = String(data: typeData, encoding: .macOSRoman)!
                    
                    let contents = data.subdata(in: index.advanced(by: 8)
                        ..< index.advanced(by: size))
                    
                    let childBlock = Block(type: type, data: contents,
                                           parent: self)
                    children.append(childBlock)
                    
                    index = index.advanced(by: size)
                }
            }
        }
        
        /// Writes the contents of this block and children to the given `Data`
        ///
        /// - parameters:
        ///   - to: The `Data` to write to
        ///
        /// - returns: The modified `Data`
        func write(_ to: Data) -> Data {
            var outData = to
            var size = UInt32(calculateSize()).bigEndian
            let sizeData = Data(bytes: &size, count:
                MemoryLayout.size(ofValue: size))

            let typeData = type.data(using: .macOSRoman)!
            
            if type == "mdat" {
                outData.append(contentsOf: ByteBlocks.fourByteOne)
            } else {
                outData.append(sizeData)
            }
            
            outData.append(typeData)
            
            if type == "meta" {
                outData.append(contentsOf: ByteBlocks.fourEmptyBytes)
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
        
        /// Calculates block sizes recursively, including children
        ///
        /// - returns: Recursive block size
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
    
    /// M4A file related errors
    public enum M4AFileError: Error {
        
        /// When a block of an unknown type is loaded
        case invalidBlockType
        /// When a file is not valid M4A
        case invalidFile
        
    }
    
    /// Metadata type identifier strings
    public enum Metadata {
        
        /// Metadata with a data type of string
        public enum StringMetadata : String {
            
            /// Album
            case album = "©alb"
            /// Artist
            case artist = "©ART"
            /// Album Artist
            case albumArtist = "aART"
            /// Comment
            case comment = "©cmt"
            /// Year
            case year = "©day"
            /// Title
            case title = "©nam"
            /// Custom Genre
            case genreCustom = "©gen"
            /// Composer
            case composer = "©wrt"
            /// Encoder
            case encoder = "©too"
            /// Copyright
            case copyright = "cprt"
            /// Compilation
            case compilation = "cpil"
            /// Lyrics
            case lyrics = "©lyr"
            /// Purchase Date
            case purchaseDate = "purd"
            /// Grouping
            case grouping =  "©grp"
            /// Unknown, can be ignored
            case misc = "----"
            /// Sorting album
            case sortingAlbum = "soal"
            /// Sorting artist
            case sortingArtist = "soar"
            /// Sorting album artist
            case sortingAlbumArtist = "soaa"
            /// Sorting composer
            case sortingComposer = "soco"
        }
        
        /// Metadata with a data type of int
        public enum IntMetadata : String {
            
            /// Genre ID
            case genreID = "gnre"
            /// Track
            case track = "trkn"
            /// Disk
            case disk = "disk"
            /// BPM
            case bpm = "tmpo"
            /// Rating
            case rating = "rtng"
            /// Gapless
            case gapless = "pgap"
            
        }
        
        /// Metadata with a date type of image
        public enum ImageMetadata: String {
            /// Artwork
            case artwork = "covr"
            
        }
        
        /// Used in order to check if metadata is recognized
        fileprivate static let allValues: [Any] = [StringMetadata.album,
                                       StringMetadata.albumArtist,
                                       StringMetadata.artist,
                                       StringMetadata.comment,
                                       StringMetadata.compilation,
                                       StringMetadata.composer,
                                       StringMetadata.copyright,
                                       StringMetadata.encoder,
                                       StringMetadata.genreCustom,
                                       StringMetadata.grouping,
                                       StringMetadata.lyrics,
                                       StringMetadata.title,
                                       StringMetadata.year,
                                       StringMetadata.misc,
                                       StringMetadata.sortingAlbum,
                                       StringMetadata.sortingArtist,
                                       StringMetadata.sortingComposer,
                                       StringMetadata.sortingAlbumArtist,
                                       
                                       IntMetadata.bpm,
                                       IntMetadata.disk,
                                       IntMetadata.gapless,
                                       IntMetadata.genreID,
                                       IntMetadata.rating,
                                       IntMetadata.track,
                                       
                                       ImageMetadata.artwork,
                                       ]
    }
    
    /// Used to check if a block is recognized
    private static let validTypes = ["ftyp", "mdat", "moov", "pnot", "udta",
                                     "uuid", "moof", "free",  "skip", "jP2 ",
                                     "wide", "load", "ctab", "imap", "matt",
                                     "kmat", "clip", "crgn", "sync", "chap",
                                     "tmcd", "scpt", "ssrc", "PICT"]
    
    /// The `Block`s in the M4A file
    internal var blocks: [Block]
    
    /// Used to get the metadata block
    internal var metadataBlock: Block? {
        return findBlock(["moov", "udta", "meta", "ilst"])
    }
    
    /// Creates an instance from data
    /// - parameters:
    ///   - data: The data of an M4A file
    /// - throws: `M4AFileError.invalidBlockType`
    public init(data: Data) throws {
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
            let typeData = data.subdata(in: index.advanced(by: 4)
                ..< index.advanced(by: 8))
            
            // Turn size into an integer
            var size = Int(UInt32(bigEndian:
                sizeData.withUnsafeBytes { $0.pointee }))
            
            let type = String(data: typeData, encoding: .macOSRoman)!
            
            guard typeIsValid(type) else {
                throw M4AFileError.invalidBlockType
            }
            
            if size == 1 && type == "mdat" {
                // mdat sometimes has a size of 1 and
                // it's size is 12 bytes into itself
                let mdatSizeData = data.subdata(in: index.advanced(by: 12)
                    ..< index.advanced(by: 16))
                size = Int(UInt32(bigEndian:
                    mdatSizeData.withUnsafeBytes { $0.pointee }))
            }
            
            // Load block
            let blockContents = data.subdata(in: index.advanced(by: 8)
                ..< index.advanced(by: size))
            
            index = index.advanced(by: size)
            
            blocks.append(Block(type: type, data: blockContents, parent: nil))
        }
        
        // See if loaded metadata identifiers are recognized
        if let meta = metadataBlock {
            for block in meta.children {
                if Metadata.StringMetadata(rawValue: block.type) == nil &&
                    Metadata.IntMetadata(rawValue: block.type) == nil &&
                    Metadata.ImageMetadata(rawValue: block.type) == nil
                    {
                        print("Unrecognized metadata type: " + block.type)
                }
            }
        }
    }
    
    /// Initizlizes `M4AFile` from a `URL`
    ///
    /// - parameters:
    ///   - url: The `URL` of an M4A file
    ///
    /// - throws: What `init(data:)` throws
    public convenience init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }
    
    /// Outputs an M4A file
    ///
    /// - parameters:
    ///   - url: The `URL` to write the file to
    ///
    /// - throws: What `Data.write(to:)` throws
    public func write(url: URL) throws {
        var data = Data()
        for block in blocks {
            data = block.write(data)
        }
        
        try data.write(to: url)
    }
    
    /// Retrieves metadata of the `String` type
    ///
    /// - parameters:
    ///   - metadata: The metadtata type
    ///
    /// - returns: A `String` if the requested key exists
    public func getStringMetadata(_ metadata: Metadata.StringMetadata)
        -> String? {
        guard let metadataContainerBlock = self.metadataBlock else {
            return nil
        }
        
        let type = metadata.rawValue
        
        guard let metaBlock = M4AFile.getMetadataBlock(metadataContainer:
            metadataContainerBlock, name: type) else {
                return nil
        }
        
        guard let data = M4AFile.readMetadata(metadata: metaBlock) else {
            return nil
        }
        
        return String(bytes: data, encoding: .utf8)
    }
    
    /// Retrieves metadata of the `UInt8` type
    ///
    /// - parameters:
    ///   - metadata: The metadtata type
    ///
    /// - returns: A `UInt8` if the requested key exists
    public func getIntMetadata(_ metadata: Metadata.IntMetadata) -> UInt8? {
        if let metadataChild = getMetadataBlock(type: metadata.rawValue) {
            guard metadataChild.data.count == 10 else {
                print("Int metadata should have 2 bytes of data!")
                return nil
            }
            return UInt8(metadataChild.data[9])
        } else {
            return nil
        }
    }
    
    /// Sets a `String` metadata key
    ///
    /// - parameters:
    ///   - metadata: The metadtata type
    ///   - value: The `String` to set the key to
    public func setStringMetadata(_ metadata: Metadata.StringMetadata,
                                  value: String) {
        // Get data to write to the metadata block
        var data = ByteBlocks.stringIdentifier
        guard let stringData = value.data(using: .utf8) else {
            print("Invalid UTF-8 string given.")
            return
        }
        data += stringData
        
        // Write the data if the block exists, create block if it doesn't
        if let block = getMetadataBlock(type: metadata.rawValue) {
            block.data = Data(data)
        } else {
            // The block doesn't exist, we need to create it
            var metadataContainer: Block! = metadataBlock
            if metadataContainer == nil {
                // Create the metadata block
                print("TODO: Create metadata block")
                metadataContainer = nil
            }
            
            data = "data".data(using: .macOSRoman)! + data
            
            var size = UInt32(data.count + 4).bigEndian
            let sizeData = Data(bytes: &size, count:
                MemoryLayout.size(ofValue: size))
            data = sizeData + data
            let block = Block(type: metadata.rawValue, data: Data(data),
                              parent: metadataContainer)
            metadataContainer.children.append(block)
        }
    }
    
    /// Sets a `UInt8` metadata key
    ///
    /// - parameters:
    ///   - metadata: The metadtata type
    ///   - value: The `UInt8` to set the key to
    public func setIntMetadata(_ metadata: Metadata.IntMetadata, value: UInt8) {
        // Get data to write to the metadata block
        var data = ByteBlocks.intIdentifier
        
        // Write the value
        data += [0x00, value]
        
        if let block = getMetadataBlock(type: metadata.rawValue) {
            // The block exists, just give it new data
            block.data = Data(data)
        } else {
            // The block doesn't exist, we need to create it
            var metadataContainer: Block! = metadataBlock
            if metadataContainer == nil {
                // Create the metadata block
                print("TODO: Create metadata block")
                metadataContainer = nil
            }
            
            data = "data".data(using: .macOSRoman)! + data
            
            var size = UInt32(data.count + 4).bigEndian
            let sizeData = Data(bytes: &size, count:
                MemoryLayout.size(ofValue: size))
            data = sizeData + data
            let block = Block(type: metadata.rawValue, data: Data(data),
                              parent: metadataContainer)
            metadataContainer.children.append(block)
        }
    }
    
    /// Gets a metadata block from the metadata container
    ///
    /// - parameters:
    ///   - metadataContainer: Contains all metadata blocks
    ///   - name: The name of the block to get
    ///
    /// - returns: The metadata block if found
    private static func getMetadataBlock(metadataContainer: Block, name: String)
        -> Block? {
        for block in metadataContainer.children {
            if block.type == name {
                return block
            }
        }
        return nil
    }
    
    /// Turns a metadata block into `Data`
    ///
    /// - parameters:
    ///   - metadata: The metadata to read
    ///
    /// - returns: `Data` if the metadata block is valid
    private static func readMetadata(metadata: Block) -> Data? {
        var data = metadata.data
        let sizeData = data[data.startIndex ..< data.startIndex.advanced(by: 4)]
        let typeData = data[data.startIndex.advanced(by: 4)
            ..< data.startIndex.advanced(by: 8)]
        let shouldBeNullData = data[data.startIndex.advanced(by: 8)
            ..< data.startIndex.advanced(by: 16)]
        data = data.advanced(by: sizeData.count + typeData.count
            + shouldBeNullData.count)
        
        let size = Int(UInt32(bigEndian:
            sizeData.withUnsafeBytes { $0.pointee }))
        guard let type = String(bytes: typeData, encoding: .macOSRoman),
            type == "data" else {
            print("Could not get metadata entry type")
            return nil
        }
        
        guard shouldBeNullData.elementsEqual(ByteBlocks.stringIdentifier) ||
            shouldBeNullData.elementsEqual(ByteBlocks.intIdentifier) else {
                print("Invalid metadata entry block " + metadata.type)
            return nil
        }
        
        guard size == shouldBeNullData.count + typeData.count + sizeData.count
            + data.count else {
            print("Invalid metadata entry block " + metadata.type)
            return nil
        }
        
        return data
    }
    
    /// Gets a metadata block when givena type
    /// - parameters:
    ///   - type: Metadata type name.
    /// - returns:
    /// The child block inside the metadata block, not the parent block.
    private func getMetadataBlock(type: String) -> Block? {
        guard let metadataContainerBlock = self.metadataBlock else {
            print("Failed to locate metadata block. Create one in the future.")
            return nil
        }
        
        guard let metaBlock = M4AFile.getMetadataBlock(metadataContainer:
            metadataContainerBlock, name: type) else {
                print("Failed to get metadata child block by type.")
            return nil
        }
        
        guard metaBlock.children.count == 1 else {
                print("Metadata entry lacked a data section.")
                return nil
        }
        
        return metaBlock.children[0]
    }
    
    /// Finds a block of the specified path
    ///
    /// - parameters:
    ///   - pathComponents: Block path components.
    ///     Given in the format `["foo", "bar", "oof"]` where `foo` is the
    ///     highest level and `oof` is the deepest level.
    ///
    /// - returns: The requested block if found
    internal func findBlock(_ pathComponents: [String]) -> Block? {
        assert(!pathComponents.isEmpty)
        
        var blocks = self.blocks
        for component in pathComponents {
            if let block = M4AFile.getBlockOneLevel(blocks: blocks,
                                                    type: component) {
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
    
    /// Gets a block from the children of another block
    ///
    /// - parameters:
    ///   - blocks: The block children
    ///   - type: The block type to search for
    ///
    /// - returns: The requested block if it exists
    private static func getBlockOneLevel(blocks: [Block], type: String)
        -> Block? {
        for block in blocks {
            if block.type == type {
                return block
            }
        }
        return nil
    }
    
    /// Checks if a block type is valid
    ///
    /// - parameters:
    ///   - type: The block type
    ///
    /// - returns: The validity of the block type
    private func typeIsValid(_ type: String) -> Bool {
        return M4AFile.validTypes.contains(type)
    }
}
