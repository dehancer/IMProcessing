//
//  IMPRgbXyz.swift
//  IMPPatchDetectorTest
//
//  Created by denis svinarchuk on 31.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd
//import IMProcessing


//
// XYZ -> dcproflut, RGB, LAB/LCH, HSV
//

public extension float3{
    
    //
    // dcproflut sources: https://www.ludd.ltu.se/~torger/dcamprof.html
    //

    public func xyz2dcproflut() ->float3 {
        return  IMPBridge.xyz2dcproflut(self)
    }

    public func xyz2rgb() -> float3 {
        return IMPBridge.xyz2rgb(self)
    }
    
    public func xyz2lab() -> float3 {        
        return IMPBridge.xyz2lab(self)
        
    }
    
    public func xyz2lch() -> float3{
        return IMPBridge.xyz2lch(self)
    }
    
    public func xyz2hsv() -> float3 {
        return IMPBridge.xyz2hsv(self)
    }
    
    public func xyz2hsl() -> float3 {
        return IMPBridge.xyz2hsl(self)
    }
    
    public func xyz2hsp() -> float3 {
        return IMPBridge.xyz2hsp(self)
    }
    
    public func xyz2ycbcrHD() -> float3 {
        return IMPBridge.xyz2ycbcrHD(self)
    }
}
