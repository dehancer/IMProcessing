//
//  IMPTriangle.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 25.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd
import Accelerate

public struct IMPTriangle {
    
    public let p0:float2
    public let pc:float2 // base vertex, center of transformation
    public let p1:float2
    
    public let aspect:Float
    
    public init(p0:float2,pc:float2,p1:float2, aspect:Float = 1){
        self.aspect = aspect
        self.p0 = float2(p0.x*aspect,p0.y)
        self.pc = float2(pc.x*aspect,pc.y)
        self.p1 = float2(p1.x*aspect,p1.y)
    }
    
    public func contains(point:float2) -> Bool {
        return IMPLineSegment(p0: p0, p1: pc).contains(point: point) || IMPLineSegment(p0: pc, p1: p1).contains(point: point)
    }
    
    public func normalIntersections(point:float2) -> [float2] {
        let line0 = IMPLineSegment(p0: p0, p1: pc)
        let line1 = IMPLineSegment(p0: p1, p1: pc)
        return [line0.normalIntersection(point: point), line1.normalIntersection(point: point)]
    }
    
//    public func distancesTo(point:float2) -> [float2] {
//        let line0 = IMPLineSegment(p0: p0, p1: pc)
//        let line1 = IMPLineSegment(p0: p1, p1: pc)
//        return [line0.distanceTo(point: point),line1.distanceTo(point: point)]
//    }
    
    /// Vector of distance from base vertex to opposite side
    public var heightVector:float2 {
        get{
            let line1 = IMPLineSegment(p0: p0, p1: p1)
            return line1.normalIntersection(point: pc) - pc
        }
    }
}

