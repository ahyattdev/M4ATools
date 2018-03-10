//
//  ByteBlocks.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 3/10/18.
//

import Foundation

/// Utility byte arrays
internal struct ByteBlocks {
    
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
    
    /// Two null bytres
    static let twoEmptyBytes: [UInt8] = [0x00, 0x00]
    
    /// Eight null bytes
    static let eightEmptyBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00,
                                           0x00, 0x00, 0x00, 0x00]
}
