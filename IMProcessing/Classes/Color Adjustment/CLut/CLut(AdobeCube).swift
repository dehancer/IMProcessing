//
//  CLut(AdobeCube).swift
//  Pods
//
//  Created by denis svinarchuk on 28.08.17.
//
//

import Foundation
import Metal
import simd

// MARK: - Create Cube from Adobe Cube Lut file
/// Load a LUT from the Adobe cube file format.
/// Cube LUT Specification Version 1.0
///  http://wwwimages.adobe.com/content/dam/Adobe/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf
public extension IMPCLut {
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context: processing context
    ///   - url: URL
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    public convenience init(context:IMPContext,  cube url: URL, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context:context, storageMode:storageMode)
        try update(cube: url.path)
    }
    
    
    /// Load data from URL (the current version is supported local file only!)
    ///
    /// - Parameters:
    ///   - context:  processing context
    ///   - path: path
    ///   - storageMode: storageMode
    /// - Throws: `FormatError`
    public convenience init(context:IMPContext,  cube path: String, storageMode:IMPImageStorageMode?=nil) throws {
        self.init(context:context, storageMode:storageMode)
        try update(cube: path)
    }
    
}

fileprivate protocol Decimals {
    func toFloat() -> Float
}

extension Float32:Decimals {
    func toFloat() -> Float {
        return Float(self)
    }
}

extension uint8:Decimals{
    func toFloat() -> Float {
        return Float(self)
    }
}

/// Load a LUT from the Adobe cube file format.
/// Cube LUT Specification Version 1.0
///  http://wwwimages.adobe.com/content/dam/Adobe/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf

// MARK: - exports
public extension IMPCLut {
    
    /// Export as Adobe Cube Lut to file
    ///
    /// - Parameter path: file path
    /// - Throws: FormatError
    public func write(cube path: String) throws {
        try autoreleasepool{
            
            if _type == .lut_2d {
                throw FormatError(file: path, line: 0, kind: .wrongType)
            }
            
            guard let txt = texture else { throw FormatError(file: path, line: 0, kind: .empty) }
            
            let file:UnsafeMutablePointer<FILE>! = fopen((path as NSString).utf8String, "w")
            
            guard file != nil else {  throw FormatError(file: path, line: 0, kind: .notCreated) }
            
            defer{
                fclose(file);
            }
            
            write(to: file, string: generatorComment+"\n\n")
            write(to: file, string: "TITLE \"\(title)\"\n\n")
            
            write(to: file, string: "#LUT size\n")
            if type == .lut_1d {
                write(to: file, string: "LUT_1D_SIZE \(_lutSize)\n")
                write(to: file, string: "LUT_1D_INPUT_RANGE \(_domainMin.r) \(_domainMax.r)\n\n")
            }
            else {
                write(to: file, string: "LUT_3D_SIZE \(_lutSize)\n\n")
            }
            
            write(to: file, string: "#Data domain\n")
            write(to: file, string: "DOMAIN_MIN \(_domainMin.r) \(_domainMin.g) \(_domainMin.b)\n")
            write(to: file, string: "DOMAIN_MAX \(_domainMax.r) \(_domainMax.g) \(_domainMax.b)\n\n")
            
            write(to: file, string: "#LUT data points\n")
            
            if _format == .float {
                let (bytes,count) =  getBytes(texture: txt) as (UnsafeMutablePointer<Float32>,Int)
                if (_type == .lut_1d) {
                    writeData(to: file, bytes: bytes, count: count, denom: 1)
                }
                else {
                    writeData3D(to: file, bytes: bytes, count: txt.width, denom: 1)
                }
            }
            else {
                let (bytes,count) =  getBytes(texture: txt) as (UnsafeMutablePointer<uint8>,Int)
                if (_type == .lut_1d) {
                    writeData(to: file, bytes: bytes, count: count, denom: 255)
                }
                else {
                    writeData3D(to: file, bytes: bytes, count: txt.width, denom: 255)
                }
            }
        }
    }
    
    private func writeData<T:Decimals>(to file:UnsafeMutablePointer<FILE>!, bytes:UnsafePointer<T>, count:Int, denom:Float){
        var j = 0
        while j<count {
            let r = bytes[j].toFloat()/denom; j += 1
            let g = bytes[j].toFloat()/denom; j += 1
            let b = bytes[j].toFloat()/denom; j += 2
                        
            write(to: file, string: String(format: "%.6f %.6f %.6f\n", r,g,b))
        }
    }
    
    private func writeData3D<T:Decimals>(to file:UnsafeMutablePointer<FILE>!, bytes:UnsafePointer<T>, count:Int, denom:Float){
        for ib in 0..<count {
            for ig in 0..<count {
                for ir in 0..<count {
                    let index = ir*4 + count*ig*4 + count*count*ib*4
                    let r = bytes[index + 0 ].toFloat()/denom
                    let g = bytes[index + 1 ].toFloat()/denom
                    let b = bytes[index + 2 ].toFloat()/denom
                    write(to: file, string: String(format: "%.6f %.6f %.6f\n", r,g,b))
                }
            }
        }
    }
         
    private func write(to fp:UnsafeMutablePointer<FILE>!, string: String) {
        let byteArray = Array(string.utf8)
        _ = fwrite(byteArray, 1, byteArray.count, fp)
    }
    
}


// MARK: - Internal update from Adobe Cube file
extension IMPCLut {
    fileprivate func update(cube path: String) throws {
        
        if (FileManager.default.fileExists(atPath: path) == false) {
            throw FormatError(file: path, line: 0, kind: .notFound)
        }
        
        let file:UnsafeMutablePointer<FILE>! = fopen((path as NSString).utf8String, "r")
        
        guard file != nil else {  throw FormatError(file: path, line: 0, kind: .notFound) }
        
        defer{
            fclose(file);
        }
        
        let useFloatLUT = _format == .float ? true : false
        
        var isData = false
        var size = 0
        var linenumber = 0
        
        try autoreleasepool{
            
            var dataBytes = Data()
            
            while let line = self.readline(file) {
                
                if line.isEmpty || line.hasPrefix("#") {
                    continue
                }
                
                let words = line.components(separatedBy: .whitespacesAndNewlines)
                
                if words.count <= 1 {
                    throw FormatError(file: path, line: linenumber, kind: .wrongFormat)
                }
                
                let keyword = words[0].uppercased()
                
                
                if keyword.hasPrefix("TITLE") {
                    _title = words[1].trimmingCharacters(in: CharacterSet(charactersIn:"\" "))
                }
                    
                else if keyword.hasPrefix("DOMAIN_MIN") {
                    if words.count==4 {
                        _domainMin.r = Float(words[1]) ?? 0
                        _domainMin.g = Float(words[2]) ?? 0
                        _domainMin.b = Float(words[3]) ?? 0
                    }
                    else{
                        throw FormatError(file: path, line: linenumber, kind: .wrongFormat)
                    }
                }
                    
                else if keyword.hasPrefix("DOMAIN_MAX") {
                    if words.count==4 {
                        _domainMax.r = Float(words[1]) ?? 0
                        _domainMax.g = Float(words[2]) ?? 0
                        _domainMax.b = Float(words[3]) ?? 0
                    }
                    else{
                        throw  FormatError(file: path, line: linenumber, kind: .wrongFormat)
                    }
                }
                    
                else if keyword.hasPrefix("LUT_3D_SIZE") {
                    if let s = Int(words[1]){
                        _lutSize = s
                    }
                    else {
                        throw  FormatError(file: path, line: linenumber, kind: .wrongFormat)
                    }
                    _type = .lut_3d
                    if  _lutSize < 2 || _lutSize > 256  {
                        throw  FormatError(file: path, line: linenumber, kind: .outOfRange)
                    }
                }
                    
                else if keyword.hasPrefix("LUT_1D_SIZE") {
                    if let s = Int(words[1]){
                        _lutSize = s
                    }
                    else {
                        throw FormatError(file: path, line: linenumber, kind: .wrongFormat)
                    }
                    _type = .lut_1d;
                    if ( _lutSize < 2 || _lutSize > 65536 ) {
                        throw FormatError(file: path, line: linenumber, kind: .outOfRange)
                    }
                }
                    
                else if keyword.hasPrefix("LUT_1D_INPUT_RANGE") {
                    if words.count==3 {
                        
                        let dmin =  Float(words[1]) ?? 0
                        let dmax =  Float(words[2]) ?? 0
                        
                        _domainMin.r=dmin
                        _domainMin.g=dmin
                        _domainMin.b=dmin
                        _domainMax.r=dmax
                        _domainMax.g=dmax
                        _domainMax.b=dmax
                    }
                    else{
                        throw FormatError(file: path, line: linenumber, kind: .wrongFormat)
                    }
                }
                    
                else if isData || keyword.isNumeric {
                    
                    if _lutSize == 0 {
                        throw FormatError(file: path, line: linenumber, kind: .empty)
                    }
                    
                    if
                        (_domainMax.r-_domainMin.r)<=0
                            ||
                            (_domainMax.g-_domainMin.g)<=0
                            ||
                            (_domainMax.b-_domainMin.b)<=0
                    {
                        throw FormatError(file: path, line: linenumber, kind: .outOfRange)
                    }
                    
                    isData = true
                    
                    let denom = Float32(!useFloatLUT ? Float32(_type == .lut_1d ? 255 : _lutSize) : 1.0)
                    
                    var r = (Float32(words[0]) ?? 0) / Float32(_domainMax.r-_domainMin.r)*denom
                    var g = (Float32(words[1]) ?? 0) / Float32(_domainMax.g-_domainMin.g)*denom
                    var b = (Float32(words[2]) ?? 0) / Float32(_domainMax.g-_domainMin.g)*denom
                    var a = denom
                    
                    if (!useFloatLUT) {
                        var ri = uint8(r)
                        var gi = uint8(g)
                        var bi = uint8(b)
                        var ai = uint8(a)
                        dataBytes.append(&ri, count: MemoryLayout<uint8>.size)
                        dataBytes.append(&gi, count: MemoryLayout<uint8>.size)
                        dataBytes.append(&bi, count: MemoryLayout<uint8>.size)
                        dataBytes.append(&ai, count: MemoryLayout<uint8>.size)
                    }
                    else{
                        dataBytes.append(UnsafeBufferPointer(start: &r, count: 1))
                        dataBytes.append(UnsafeBufferPointer(start: &g, count: 1))
                        dataBytes.append(UnsafeBufferPointer(start: &b, count: 1))
                        dataBytes.append(UnsafeBufferPointer(start: &a, count: 1))
                    }
                    
                    size += 1
                }
                    
                else {
                    throw FormatError(file: path, line: linenumber, kind: .wrongFormat)
                }
                
                linenumber += 1
            }
            
            
            if _title.isEmpty {
                _title = URL(fileURLWithPath: path).lastPathComponent
            }
            
            var componentBytes = MemoryLayout<uint8>.size
            
            if (useFloatLUT) {
                componentBytes = MemoryLayout<Float32>.size
            }
            
            let width  = _lutSize
            let height = _type == .lut_1d ? 1 : _lutSize
            let depth  = _type == .lut_1d ? 1 : _lutSize
            
            texture = try makeTexture(size: _lutSize, type: _type, format: _format)
            
            let region = _type == .lut_1d ?MTLRegionMake2D(0, 0, width, 1):MTLRegionMake3D(0, 0, 0, width, height, depth)
            
            let bytesPerPixel = 4 * componentBytes
            let bytesPerRow   = bytesPerPixel * width
            let bytesPerImage = bytesPerRow * height
            
            texture?.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: (dataBytes as NSData).bytes, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
            
        }
        
    }
    
    private func readline(_ file:UnsafeMutablePointer<FILE>) -> String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        var linecap:Int = 0
        defer { free(line) }
        return getline(&line, &linecap, file) > 0 ? String(cString:line!).trimmingCharacters(in:.whitespacesAndNewlines) : nil
    }
    
}

