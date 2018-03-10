//
//  Block.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 3/10/18.
//

import Foundation

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
    
    var largeAtomSize = false
    
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
        
        if type == "mdat" && largeAtomSize {
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
