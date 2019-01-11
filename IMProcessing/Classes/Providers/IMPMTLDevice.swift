//
//  IMPMTLDevice.swift
//  IMPCameraManager
//
//  Created by denis svinarchuk on 23.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Metal

public extension MTLDevice {
    
    public func texture1D(buffer:[Float]) -> MTLTexture {
        let weightsDescription = MTLTextureDescriptor()
        
        weightsDescription.textureType = .type1D
        weightsDescription.pixelFormat = .r32Float
        weightsDescription.width       = buffer.count
        weightsDescription.height      = 1
        weightsDescription.depth       = 1
        weightsDescription.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]

        let texture = self.makeTexture(descriptor: weightsDescription)
        texture?.update(buffer)
        return texture!
    }
    
    public func texture1D(buffer:[UInt8]) -> MTLTexture {
        let weightsDescription = MTLTextureDescriptor()
        
        weightsDescription.textureType = .type1D
        weightsDescription.pixelFormat = .r8Uint
        weightsDescription.width       = buffer.count
        weightsDescription.height      = 1
        weightsDescription.depth       = 1
        weightsDescription.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
        let texture = self.makeTexture(descriptor: weightsDescription)
        texture?.update(buffer)
        return texture!
    }
    
    public func texture2D(buffer:[[UInt8]]) -> MTLTexture {
        let width = buffer[0].count
        let weightsDescription = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width, height: buffer.count, mipmapped: false)
        weightsDescription.usage = [.shaderRead,.shaderWrite,.pixelFormatView,.renderTarget]
        let texture = self.makeTexture(descriptor: weightsDescription)
        texture?.update(buffer)
        return texture!
    }
    
    public func texture1DArray(buffers:[[UInt8]]) -> MTLTexture {
        
        let width = buffers[0].count
        
        for i in 1 ..< buffers.count {
            if (width != buffers[i].count) {
                fatalError("texture buffers must have identical size...")
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type1DArray
        textureDescriptor.width       = width
        textureDescriptor.height      = 1
        textureDescriptor.depth       = 1
        textureDescriptor.pixelFormat = .r8Unorm
        
        textureDescriptor.arrayLength = buffers.count
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]

        let texture = self.makeTexture(descriptor: textureDescriptor)
        
        texture?.update1DArray(buffers)
        
        return texture!
    }
    
    public func texture1DArray(buffers:[[Float]]) -> MTLTexture {
        
        let width = buffers[0].count
        
        for i in 1 ..< buffers.count {
            if (width != buffers[i].count) {
                fatalError("texture buffers must have identical size...")
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type1DArray
        textureDescriptor.width       = width
        textureDescriptor.height      = 1
        textureDescriptor.depth       = 1
        textureDescriptor.pixelFormat = .r32Float
        
        textureDescriptor.arrayLength = buffers.count
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
        let texture = self.makeTexture(descriptor: textureDescriptor)
        
        texture?.update(buffers)
        
        return texture!
    }
    
    public func make2DTexture(width:Int, height:Int,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                         width: width,
                                                         height: height,
                                                         mipmapped: false)
        if mode == .shared {
            #if os(iOS)
                d.storageMode = .shared
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #elseif os(OSX)
                d.storageMode = .managed
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #endif
        }
        else {
            d.storageMode = .private
            d.usage = [.shaderRead,.shaderWrite,.pixelFormatView]
        }
        return makeTexture(descriptor:d)!
    }
 
    public func make2DTexture(size: MTLSize,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                         width: Int(size.width),
                                                         height: Int(size.height),
                                                         mipmapped: false)
        if mode == .shared {
            #if os(iOS)
                d.storageMode = .shared
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #elseif os(OSX)
                d.storageMode = .managed
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #endif
        }
        else {
            d.storageMode = .private
            d.usage = [.shaderRead,.shaderWrite,.pixelFormatView,.renderTarget]
        }
        return makeTexture(descriptor:d)!
    }
    
    public func make2DTexture(size: NSSize,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                 width: Int(size.width),
                                                 height: Int(size.height),
                                                 mipmapped: false)
        if mode == .shared {
            #if os(iOS)
                d.storageMode = .shared
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #elseif os(OSX)
                d.storageMode = .managed
                d.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #endif
        }
        else {
            d.storageMode = .private
            d.usage = [.shaderRead,.shaderWrite,.pixelFormatView,.renderTarget]
        }

        return makeTexture(descriptor:d)!
    }
}
