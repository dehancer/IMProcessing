//
//  IMPSimdRgb.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

func IMPstep(_ edge:Float, _ x:Float) -> Float {
    return step(x, edge: edge)
}

//
// RGB -> dcproflut, XYZ, LAB/LCH, HSV
//

public extension float3{
    
    public func rgb2srgb() -> float3 {
        return IMPBridge.rgb2srgb(self)
    }
    
    public func rgb2xyz() -> float3 {
        return IMPBridge.rgb2xyz(self)
    }
    
    public func rgb2hsv() -> float3 {
        return IMPBridge.rgb2hsv(self)
    }
    
    public func rgb2hsl() -> float3 {
        return IMPBridge.rgb2hsl(self)
    }
    
    public func rgb2hsp() -> float3 {
        return IMPBridge.rgb2hsp(self)
    }

    public func rgb2ycbcrHD() -> float3 {
        return IMPBridge.rgb2ycbcrHD(self)
    }

    public func rgb2dcproflut() ->float3 {
        return IMPBridge.rgb2dcproflut(self)
    }
    
    public func rgb2lab() -> float3 {
        return  IMPBridge.rgb2lab(self)
    }

       public func rgb2lch() -> float3 {
        return IMPBridge.rgb2lch(self)
    }
}


public extension float3{
    
    public func srgb2xyz() -> float3 {
        return IMPBridge.srgb2xyz(self)
    }
    
    public func srgb2rgb() -> float3 {
        return IMPBridge.srgb2rgb(self)
    }
    
    public func srgb2hsv() -> float3 {
        return IMPBridge.srgb2hsv(self)
    }
    
    public func srgb2hsl() -> float3 {
        return IMPBridge.srgb2hsl(self)
    }
    
    public func srgb2hsp() -> float3 {
        return IMPBridge.srgb2hsp(self)
    }
    
    public func srgb2ycbcrHD() -> float3 {
        return IMPBridge.srgb2ycbcrHD(self)
    }
    
    public func srgb2dcproflut() ->float3 {
        return IMPBridge.srgb2dcproflut(self)
    }
    
    public func srgb2lab() -> float3 {
        return  IMPBridge.srgb2lab(self)
    }
    
    public func srgb2lch() -> float3 {
        return IMPBridge.srgb2lch(self)
    }
}
