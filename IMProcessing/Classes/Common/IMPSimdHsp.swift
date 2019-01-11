//
//  IMPSimdHsp.swift
//  Pods
//
//  Created by denis svinarchuk on 10.06.17.
//
//

import Foundation
import simd

//
// HSL -> RGB, XYZ, LAB/LCH, DCamProf LUT
//

public extension float3{
    
    public func hsp2rgb() -> float3 {
        return IMPBridge.hsp2rgb(self)
    }
    
    public func hsp2ycbcrHD() -> float3 {
        return IMPBridge.hsp2ycbcrHD(self)
    }
    
    public func hsp2lab() -> float3 {
        return IMPBridge.hsp2lab(self)
    }
    
    public func hsp2hsv() -> float3 {
        return IMPBridge.hsp2hsv(self)
    }
    
    public func hsp2hsl() -> float3 {
        return IMPBridge.hsp2hsl(self)
    }
    
    public func hsp2lch() -> float3 {
        return IMPBridge.hsp2lch(self)
    }
    
    public func hsp2xyz() -> float3 {
        return IMPBridge.hsp2xyz(self)
    }
    
    public func hsp2dcproflut() -> float3 {
        return IMPBridge.hsp2dcproflut(self)
    }

}
