//
//  IMPHsv.swift
//  Pods
//
//  Created by Denis Svinarchuk on 03/05/2017.
//
//

import Foundation
import simd

//
// HSV -> RGB, XYZ, LAB/LCH, dcproflut
//

public extension float3{
        
    public func hsv2rgb() -> float3 {
        return IMPBridge.hsv2rgb(self)
    }
    
    public func hsv2hsl() -> float3 {
        return IMPBridge.hsv2hsl(self)
    }
    
    public func hsv2hsp() -> float3 {
        return IMPBridge.hsv2hsp(self)
    }
    
    public func hsv2ycbcrHD() -> float3 {
        return IMPBridge.hsv2ycbcrHD(self)
    }
    
    public func hsv2lab() -> float3 {
        return IMPBridge.hsv2lab(self)
    }
    
    public func hsv2lch() -> float3 {
        return IMPBridge.hsv2lch(self)
    }
    
    public func hsv2xyz() -> float3 {
        return IMPBridge.hsv2xyz(self)
    }
    
    public func hsv2dcproflut() -> float3 {
        return IMPBridge.hsv2dcproflut(self)
    }

}
