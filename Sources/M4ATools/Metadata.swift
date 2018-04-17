//
//  Metadata.swift
//  M4ATools
//
//  Created by Andrew Hyatt on 3/10/18.
//

import Foundation

/// Metadata type identifier strings
public struct Metadata {
    
    /// Hidden
    private init() { }
    
    /// Metadata with a data type of string
    /// Takes up a variant amount of bytes
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
        /// Can be 4 digit year or release date
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
        /// Purchase date
        case purchaseDate = "purd"
        /// Grouping
        case grouping =  "©grp"
        /// Unknown, can be ignored
        case misc = "----"
        /// Sorting title
        case sortingTitle = "sonm"
        /// Sorting album
        case sortingAlbum = "soal"
        /// Sorting artist
        case sortingArtist = "soar"
        /// Sorting album artist
        case sortingAlbumArtist = "soaa"
        /// Sorting composer
        case sortingComposer = "soco"
        /// Apple ID used to purchase
        case appleID = "apID"
        /// Owner
        case owner = "ownr"
        /// iTunes XID
        ///
        /// https://images.apple.com/itunes/lp-and-extras/docs/Development_Guide.pdf
        ///
        /// Yes, it has a space in it 🙄
        case xid = "xid "
        /// Work
        case work = "©wrk"
        /// Movement
        case movement = "©mvn"
        
    }
    
    /// 8-bit integer metadata
    /// The metadata child takes up 9 bytes in the file
    public enum UInt8Metadata: String {
        
        /// Rating
        case rating = "rtng"
        /// Gapless
        case gapless = "pgap"
        /// Media type
        case mediaType = "stik"
        /// Genre ID
        ///
        /// Old, use `UInt32Metadata.genreID` instead
        case genreID = "gnre"
        /// Compilation
        case compilation = "cpil"
        /// Show movement
        case showMovement = "shwm"
        
    }
    
    /// 16-bit integer metadata
    /// The metadata child takes up 10 bytes in the file
    public enum UInt16Metadata: String {
        
        /// BPM
        case bpm = "tmpo"
        /// Movement number
        case movementNumber = "©mvi"
        /// Movement count
        case movementCount = "©mvc"
        
        
    }
    
    /// 32-bit integer metadata
    /// Takes up 12 bytes in the file
    public enum UInt32Metadata: String {
        
        /// Artist ID
        case artistID = "atID"
        /// Genre ID
        case genreID = "geID"
        /// iTunes Catalog ID
        case catalogID = "cnID"
        /// iTunes country code
        case countryCode = "sfID"
        /// Composer ID
        case composerID = "cmID"
        
    }
    
    /// 64-bit integer metadata
    /// Takes up 16 bytes in the file
    public enum UInt64Metadata: String {
        
        /// Collection ID
        case collectionID = "plID"
    }
    
    /// Metadata consisting of two 16-bit integers
    /// Takes up 16 bytes in the file
    public enum TwoIntMetadata : String {
        
        /// Track
        case track = "trkn"
        /// Disc
        case disc = "disk"
        
    }
    
    /// Metadata with a date type of image
    public enum ImageMetadata: String {
        /// Artwork
        case artwork = "covr"
        
    }
    
    /// Used in order to check if metadata is recognized
    internal static let allValues: [Any] = [StringMetadata.album,
                                            StringMetadata.albumArtist,
                                            StringMetadata.artist,
                                            StringMetadata.comment,
                                            StringMetadata.composer,
                                            StringMetadata.copyright,
                                            StringMetadata.encoder,
                                            StringMetadata.genreCustom,
                                            StringMetadata.grouping,
                                            StringMetadata.lyrics,
                                            StringMetadata.title,
                                            StringMetadata.year,
                                            StringMetadata.misc,
                                            StringMetadata.sortingTitle,
                                            StringMetadata.sortingAlbum,
                                            StringMetadata.sortingArtist,
                                            StringMetadata.sortingComposer,
                                            StringMetadata.sortingAlbumArtist,
                                            StringMetadata.appleID,
                                            StringMetadata.owner,
                                            StringMetadata.xid,
                                            StringMetadata.work,
                                            StringMetadata.movement,
                                            
                                            UInt8Metadata.gapless,
                                            UInt8Metadata.genreID,
                                            UInt8Metadata.rating,
                                            UInt8Metadata.compilation,
                                            UInt8Metadata.showMovement,
                                            
                                            UInt16Metadata.bpm,
                                            UInt16Metadata.movementNumber,
                                            UInt16Metadata.movementCount,
                                            
                                            UInt32Metadata.catalogID,
                                            UInt32Metadata.countryCode,
                                            UInt32Metadata.artistID,
                                            UInt32Metadata.genreID,
                                            UInt32Metadata.composerID,
                                            
                                            UInt64Metadata.collectionID,
                                            
                                            TwoIntMetadata.track,
                                            TwoIntMetadata.disc,
                                            
                                            ImageMetadata.artwork,
                                            ]
}
