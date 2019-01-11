//
//  IMPPolarLine.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 25.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

public class IMPPolarLine{
    
    public var vector:float2 = float2()

    public required init() {}

    public init(segment:IMPLineSegment, size:NSSize = NSSize(width:1,height:1)){
        let p = segment.polarLine(size: size)
        rho = p.rho
        theta = p.theta
    }
    
    public convenience init(p0:float2, p1:float2, size:NSSize = NSSize(width:1,height:1)){
        self.init(segment: IMPLineSegment(p0: p0, p1: p1), size: size)
    }

    
    public required init(rho:Float, theta:Float) {
        vector.x = rho
        vector.y = theta
    }
    
    public var rho: Float {
        set{ vector.x = newValue }
        get{ return vector.x }
    }
    
    public var theta: Float{
        set{ vector.y = newValue }
        get{ return vector.y }
    }
        
    //
    // http://stackoverflow.com/questions/10533233/opencv-c-obj-c-advanced-square-detection
    //
    
    public func isPair(to line2:IMPPolarLine, minTheta:Float = Float.pi/32) -> Bool {
        
        if theta < minTheta { theta +=  Float.pi }
        
        var theta2 = line2.theta
        if theta2 < minTheta { theta2 += Float.pi }
        
        return abs(theta - theta2) > minTheta
    }
        
    // the long nasty wikipedia line-intersection equation
    public func intersect(with line2: IMPPolarLine) -> float2 {
        let p1 = lineSegment
        let p2 = line2.lineSegment
        
        let denom = (p1.p0.x - p1.p1.x)*(p2.p0.y - p2.p1.y) -
            (p1.p0.y - p1.p1.y)*(p2.p0.x - p2.p1.x)
        
        let intersect = float2(
            ((p1.p0.x*p1.p1.y - p1.p0.y*p1.p1.x)*(p2.p0.x - p2.p1.x) -
                (p1.p0.x - p1.p1.x)*(p2.p0.x*p2.p1.y - p2.p0.y*p2.p1.x)) / denom,
            
            ((p1.p0.x*p1.p1.y - p1.p0.y*p1.p1.x)*(p2.p0.y - p2.p1.y) -
                (p1.p0.y - p1.p1.y)*(p2.p0.x*p2.p1.y - p2.p0.y*p2.p1.x)) / denom
        )
        
        return intersect
    }
    
    public var lineSegment:IMPLineSegment {
        get{
            let cos_t = cos(theta)
            let sin_t = sin(theta)
            let x0 = rho * cos_t
            let y0 = rho * sin_t
            let alpha:Float = 1000
            
            let p0 = float2(x0 + alpha * (-sin_t), y0 + alpha * cos_t)
            let p1 = float2(x0 - alpha * (-sin_t), y0 - alpha * cos_t)
            
            return IMPLineSegment(p0: p0, p1: p1)
        }
    }
}

extension IMPPolarLine: Equatable{
    public static func == (lhs: IMPPolarLine, rhs: IMPPolarLine) -> Bool {
        return (abs(lhs.rho - rhs.rho) < Float.ulpOfOne) && (abs(lhs.theta - rhs.theta) < Float.ulpOfOne)
    }
}
