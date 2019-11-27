//
//  CLut(HaldImage).swift
//  Pods
//
//  Created by denis svinarchuk on 28.08.17.
//
//

import Foundation
import ImageIO
import Metal
import simd

// MARK: - Create Cube from Adobe Cube Lut file
///
///
/// Any color correction can be expressed as a Color LookUp Table or CLUT (some times written as "Color LUT").
/// This a 3D dimensional table where all colors are represented in color space. For each color in the color 
/// lookup table there is a destination color value that corresponds to what the particular color becomes 
/// when it is corrected using the CLUT.
/// These tables are by nature 3-dimensional (Red Green and Blue) and therefore special file formats are used to store them. 
/// Hald CLUTs however have been converted to a 2D space and since tables store colors the CLUT can be be saved 
/// as a image, in any non destructive image format.
///
/// http://www.quelsolaar.com/technology/clut.html
///
public extension IMPCLut {
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context: processing context
    ///   - url: URL
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    convenience init(context:IMPContext,  haldImage url: URL, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context: context, url: url)
        try checkFormat(url: url)
    }
    
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context:  processing context
    ///   - path: path
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    convenience init(context:IMPContext,  haldImage path: String, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context: context, path: path)
        try checkFormat(url: URL(fileURLWithPath:path))
    }
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context:  processing context
    ///   - haldImage: hald image
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    convenience init(context:IMPContext,  haldImage image: NSImage, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context: context, image: image)
        try checkFormat(image: image)
    }
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context:  processing context
    ///   - haldImage: hald image
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    convenience init(context:IMPContext,  haldImage image: CGImage, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context: context, image: image)
        try checkFormat(image: image)
    }
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context:  processing context
    ///   - haldImage: hald image
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    convenience init(context:IMPContext,  haldImage image: CIImage, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context: context, image: image)
        try checkFormat(image: image)
    }
    
    /// Load data from URL (the current version is supported local file only!)
       ///
       /// - Parameters:
       ///   - context:  processing context
       ///   - data: hald image
       ///   - storageMode: storageMode
       /// - Throws: `FormatError`
       convenience init(context:IMPContext,  haldImage data: Data, storageMode:IMPImageStorageMode?=nil) throws {
           self.init(context: context, data: data)
           try checkFormat(data: data)
       }
}

extension IMPCLut {
    fileprivate func checkFormat(url:URL) throws {
        
        let path = url.absoluteString
        
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        
        if text.width != text.height {
            throw FormatError(file: path, line: 0, kind: .wrongFormat)
        }
        
        if !text.width.isPowerOfTwo {
            throw FormatError(file: path, line: 0, kind: .wrongFormat)
        }
        _type = .lut_2d
        _title = url.lastPathComponent
        let level = Int(round(pow(Float(text.width), 1.0/3.0)))
        _lutSize = level*level
    }
    
    fileprivate func checkFormat(image:NSImage) throws {
        
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        
        if Int(image.size.width) != text.height {
            throw FormatError(file: "", line: 0, kind: .wrongFormat)
        }
        
        _type = .lut_2d
        
        let level = Int(round(pow(Float(text.width), 1.0/3.0)))
        _lutSize = level*level
    }
    
    fileprivate func checkFormat(image:CGImage) throws {
        
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        
        if Int(image.width) != text.height {
            throw FormatError(file: "", line: 0, kind: .wrongFormat)
        }
        
        _type = .lut_2d
        
        let level = Int(round(pow(Float(text.width), 1.0/3.0)))
        _lutSize = level*level
    }
    
    fileprivate func checkFormat(image:CIImage) throws {
        
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        
        if Int(image.extent.size.width) != text.height {
            throw FormatError(file: "", line: 0, kind: .wrongFormat)
        }
        
        _type = .lut_2d
        
        let level = Int(round(pow(Float(text.width), 1.0/3.0)))
        _lutSize = level*level
    }
    
    fileprivate func checkFormat(data:Data) throws {
        
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        
        _type = .lut_2d
        
        let level = Int(round(pow(Float(text.width), 1.0/3.0)))
        _lutSize = level*level
    }
}
