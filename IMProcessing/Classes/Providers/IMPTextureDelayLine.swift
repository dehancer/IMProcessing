//
//  IMPTextureDelayLine.swift
//  Pods
//
//  Created by Denis Svinarchuk on 21/02/2017.
//
//

import Metal

public class IMPTextureDelayLine{
    
    public func request() -> MTLTexture? {
        let t = texture
        texture = nil
        return t
    }
    
    public func pushBack(texture new:MTLTexture) -> MTLTexture? {
        let t = texture
        texture = new
        return t
    }
    
    public func pushFront(texture old:MTLTexture) -> MTLTexture? {
        if texture == nil {
            texture = old
            return nil
        }
        return old
    }

    public func flush() {
        texture = nil
    }
    
    var texture:MTLTexture? = nil    
}

