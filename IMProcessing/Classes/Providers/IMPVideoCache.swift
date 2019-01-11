//
//  IMPVideoCache.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import AVFoundation
import CoreMedia

public class IMPVideoTextureCache {
    
    public init(context:IMPContext) {
        let textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device, nil, &videoTextureCache)
        if textureCacheError != kCVReturnSuccess {
            fatalError("IMPVideoTextureCache error: couldn't create a texture cache...");
        }
    }
    
    open func flush(){
        if let cache =  videoTextureCache {
            CVMetalTextureCacheFlush(cache, 0)
        }
    }
    
    var videoTextureCache: CVMetalTextureCache? = nil
    
    deinit {
        flush()
        videoTextureCache = nil
    }
}
