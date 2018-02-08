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
        
    }
    
    public enum M4AFileError: Error {
        
        case invalidBlockType
        case invalidFile
        
    }
    
    private static let validTypes = ["ftyp", "mdat", "moov", "pnot", "udta", "uuid", "moof", "free",
                                     "skip", "jP2 ", "wide", "load", "ctab", "imap", "matt", "kmat", "clip",
                                     "crgn", "sync", "chap", "tmcd", "scpt", "ssrc", "PICT"]
    
    public var blocks: [Block]
    
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
            
            let type = String(data: typeData, encoding: .utf8)!
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
        }
        print(blocks)
    }
    
    public func write(url: URL) {
        
    }
    
    private func typeIsValid(_ type: String) -> Bool {
        return M4AFile.validTypes.contains(type)
    }
    
}
