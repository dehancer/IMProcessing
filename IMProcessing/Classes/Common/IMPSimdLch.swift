//
//  IMPSimdLch.swift
//  Pods
//
//  Created by Denis Svinarchuk on 03/05/2017.
//
//

import Foundation
import simd

// LCH -> RGB, XYZ, LAB, dcproflut, HSV

public extension float3{
        
    public func lch2lab() -> float3 {
        // let l = x
        // let c = y
        // let h = z
        return IMPBridge.lch2lab(self)
    }
    
    public func lch2rgb() -> float3 {
        return IMPBridge.lch2rgb(self)
    }
    
    public func lch2hsv() -> float3 {
        return IMPBridge.lch2hsv(self)
    }

    public func lch2hsl() -> float3 {
        return IMPBridge.lch2hsl(self)
    }
    
    public func lch2hsp() -> float3 {
        return IMPBridge.lch2hsp(self)
    }
    
    public func lch2dcproflut() -> float3 {
        return IMPBridge.lch2dcproflut(self)
    }

    public func lch2xyz() -> float3 {
        return IMPBridge.lch2xyz(self)
    }
    
    public func lch2ycbcrHD() -> float3 {
        return IMPBridge.lch2ycbcrHD(self)
    }
}
