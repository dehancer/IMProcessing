//
//  IMPSimdLut.swift
//  Pods
//
//  Created by Denis Svinarchuk on 03/05/2017.
//
//

import Foundation
import simd
//import IMProcessing

//
// dcproflut sources: https://www.ludd.ltu.se/~torger/dcamprof.html
//

//
// dcproflut -> RGB, XYZ, LAB/LCH, HSV
//
public extension float3{
    
    public var L:Float { set{ x = newValue } get{ return x } }
    public var u:Float { set{ y = newValue } get{ return y } }
    public var v:Float { set{ z = newValue } get{ return z } }
    
    public func dcproflut2xyz() -> float3
    {
        return IMPBridge.dcproflut2xyz(self) 
    }
    
    public func dcproflut2rgb() -> float3 {
        return IMPBridge.dcproflut2rgb(self)
    }
    
    public func dcproflut2lab() -> float3 {
        return IMPBridge.dcproflut2lab(self)
    }

    public func dcproflut2lch() -> float3 {
        return IMPBridge.dcproflut2lch(self)
    }

    public func dcproflut2hsv() -> float3 {
        return IMPBridge.dcproflut2hsv(self)
    }

    public func dcproflut2hsl() -> float3 {
        return IMPBridge.dcproflut2hsl(self)
    }
    
    public func dcproflut2hsp() -> float3 {
        return IMPBridge.dcproflut2hsp(self)
    }
    
    public func dcproflut2ycbcrHD() -> float3 {
        return IMPBridge.dcproflut2ycbcrHD(self)
    }
    
}
