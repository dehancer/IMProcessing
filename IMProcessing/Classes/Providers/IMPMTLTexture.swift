//
//  IMPMTLTexture.swift
//  IMPCameraManager
//
//  Created by denis svinarchuk on 23.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Metal

public func == (left:MTLSize, right:MTLSize) -> Bool{
    return left.width==right.width && left.height==right.height && left.depth==left.depth
}

public func != (left:MTLSize, right:MTLSize) -> Bool{
    return !(left==right)
}

public extension MTLTexture{
    public var cgsize:NSSize{
        get{
            return NSSize(width: width, height: height)
        }
    }
    public var size:MTLSize {
        return MTLSize(width: width, height: height, depth: depth)
    }
}

public extension MTLTexture {
       
    public func validateSize(of texture:MTLTexture) -> Bool {
        return texture.size == self.size
    }
    
    public static func reuseFor(_ device:MTLDevice, texture:MTLTexture?, width:Int, height:Int, depth:Int = 1,
                                pixelFormat: MTLPixelFormat = .r8Unorm) -> MTLTexture? {
        
        guard let texture = texture else {
            return device.make2DTexture(width: width, height: height, pixelFormat: pixelFormat)
        }
        if MTLSize(width: width, height: height,depth: depth) == texture.size {
            return texture
        }
        return device.make2DTexture(width: width, height: height, pixelFormat: pixelFormat)
    }
    
    public static func reuseFor(_ device:MTLDevice, texture:MTLTexture?, size:NSSize, depth:Int = 1,
                                pixelFormat: MTLPixelFormat = .r8Unorm) -> MTLTexture? {
        return reuseFor(device,
                        texture: texture,
                        width: Int(size.width), height: Int(size.height),
                        depth: depth, pixelFormat: pixelFormat)
    }
    
    public func reuse(width:Int, height:Int, depth:Int = 1) -> MTLTexture {
        if MTLSize(width: width, height: height,depth: depth) == self.size {
            return self
        }
        return device.make2DTexture(width: width, height: height, pixelFormat: pixelFormat)
    }
    
    public func reuse(size:NSSize, depth:Int = 1) -> MTLTexture {
        return reuse(width: Int(size.width), height: Int(size.height), depth: depth)
    }
    
    public func update(_ buffer:[Float]){
        if pixelFormat != .r32Float {
            fatalError("MTLTexture.update(buffer:[Float]) has wrong pixel format...")
        }
        if width != buffer.count {
            fatalError("MTLTexture.update(buffer:[Float]) is not equal texture size...")
        }
        self.replace(region: MTLRegionMake1D(0, buffer.count), mipmapLevel: 0, withBytes: buffer, bytesPerRow: MemoryLayout<Float32>.size*buffer.count)
    }
    
    public func update(_ buffer:[UInt8]){
        if pixelFormat != .r8Uint {
            fatalError("MTLTexture.update(buffer:[UInt8]) has wrong pixel format...")
        }
        if width != buffer.count {
            fatalError("MTLTexture.update(buffer:[UInt8]) is not equal texture size...")
        }
        self.replace(region: MTLRegionMake1D(0, buffer.count), mipmapLevel: 0, withBytes: buffer, bytesPerRow: MemoryLayout<UInt8>.size*buffer.count)
    }
    
    public func update(_ buffer:[[UInt8]]){
        if pixelFormat != .r8Unorm {
            fatalError("MTLTexture.update(buffer:[UInt8]) has wrong pixel format...")
        }
        if width != buffer[0].count {
            fatalError("MTLTexture.update(buffer:[UInt8]) is not equal texture size...")
        }
        if height != buffer.count {
            fatalError("MTLTexture.update(buffer:[UInt8]) is not equal texture size...")
        }
        for i in 0 ..< height {
            self.replace(region: MTLRegionMake2D(0, i, width, 1), mipmapLevel: 0, withBytes: buffer[i], bytesPerRow: width)
        }
    }
    
    public func update1DArray(_ buffers:[[UInt8]]){
        if pixelFormat != .r8Unorm {
            fatalError("MTLTexture.update(buffer:[[UInt8]]) has wrong pixel format...")
        }
        
        let region = MTLRegionMake2D(0, 0, width, 1)
        let bytesPerRow = region.size.width * MemoryLayout<UInt8>.size
        
        for index in 0 ..< buffers.count {
            let curve = buffers[index]
            if width != curve.count {
                fatalError("MTLTexture.update(buffer:[[UInt8]]) is not equal texture size...")
            }
            self.replace(region: region, mipmapLevel:0, slice:index, withBytes:curve, bytesPerRow:bytesPerRow, bytesPerImage:0)
        }
    }
    
    public func update1DArray(_ buffers:[[Float]]){
        update(buffers)
    }
    
    public func update(_ buffers:[[Float]]){
        if pixelFormat != .r32Float {
            fatalError("MTLTexture.update(buffer:[[Float]]) has wrong pixel format...")
        }
        
        let region = MTLRegionMake2D(0, 0, width, 1)
        let bytesPerRow = region.size.width * MemoryLayout<Float32>.size
        
        for index in 0 ..< buffers.count {
            let curve = buffers[index]
            if width != curve.count {
                fatalError("MTLTexture.update(buffer:[[Float]]) is not equal texture size...")
            }
            self.replace(region: region, mipmapLevel:0, slice:index, withBytes:curve, bytesPerRow:bytesPerRow, bytesPerImage:0)
        }
    }
}

public extension IMPImageProvider {
    public func copyTexture() -> MTLTexture? {
        
        guard let texture = self.texture else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        
        textureDescriptor.textureType = texture.textureType
        textureDescriptor.width  = texture.width
        textureDescriptor.height = texture.height
        textureDescriptor.depth  = texture.depth
        textureDescriptor.usage  = texture.usage
        
        textureDescriptor.pixelFormat = texture.pixelFormat
        
        if let t = context.device.makeTexture(descriptor: textureDescriptor),
            let commandBuffer = context.commandQueue?.makeCommandBuffer(){
            
            let blt = commandBuffer.makeBlitCommandEncoder()
            
            blt?.copy(from: texture,
                      sourceSlice: 0,
                      sourceLevel: 0,
                      sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                      sourceSize: texture.size,
                      to: t,
                      destinationSlice: 0,
                      destinationLevel: 0,
                      destinationOrigin:  MTLOrigin(x:0,y:0,z:0))
            
            blt?.endEncoding()
            
            commandBuffer.commit()
            
            return t
        }
        
        return nil
    }
}
