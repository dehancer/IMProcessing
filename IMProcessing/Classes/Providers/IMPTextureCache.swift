//
//  IMPTextureCache.swift
//  Pods
//
//  Created by Denis Svinarchuk on 21/02/2017.
//
//

import Foundation
import Metal

typealias IMPTextureQueue = IMPDequeue<MTLTexture>

public class IMPTextureCache: IMPContextProvider {
    
    private var cache = [Int64:IMPTextureQueue]()
    
    public var context:IMPContext
    
    public init(context:IMPContext) {
        self.context = context
    }

    public func requestTexture(size: MTLSize, pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat) -> MTLTexture? {
        let hash = hashFor(size: size, pixelFormat: pixelFormat)
        var texture:MTLTexture?
        if let t = cache[hash]?.dequeue() {
            texture = t
        }
        else {
            let t = context.device.make2DTexture(size: size, pixelFormat: pixelFormat)
            var q = IMPTextureQueue()
            q.enqueue(t)
            cache[hash] = q
            texture = cache[hash]?.dequeue()
        }
                
        return texture
    }
    
    public func requestTexture(size: NSSize, pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat) -> MTLTexture? {
        return requestTexture(size: MTLSize(width: Int(size.width), height: Int(size.height),depth: 1), pixelFormat: pixelFormat)
    }
    
    public func requestTexture(like texture: MTLTexture) -> MTLTexture?  {
        return requestTexture(size: texture.size, pixelFormat: texture.pixelFormat)
    }
    
    public func returnTexure(_ texture:MTLTexture){
        context.runOperation(.sync) {
            let hash = self.hashFor(texture: texture)
            
            if self.cache[hash] == nil {
                self.cache[hash] =  IMPTextureQueue()
            }
            self.cache[hash]?.enqueue(texture)
        }
    }
    
    func hashFor(size: MTLSize, pixelFormat:MTLPixelFormat) -> Int64 {
        var result:Int64 = 1
        let prime:Int64 = 31
        result = prime * result + Int64(size.width)
        result = prime * result + Int64(size.height)
        result = prime * result + Int64(size.depth)
        result = prime * result + Int64(pixelFormat.rawValue)
        return result
        
    }
    
    func hashFor(texture: MTLTexture) -> Int64 {
        return hashFor(size: texture.size, pixelFormat: texture.pixelFormat)
    }
    
    func flush() {
        for var (_,q) in cache {
            var t = q.dequeue()
            while (t != nil) {
                t = q.dequeue()
            }
        }
        cache.removeAll()
    }
    
    deinit {
        flush()
    }
    
}

