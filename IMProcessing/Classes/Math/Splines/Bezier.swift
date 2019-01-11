//
//  Bezier.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 14.04.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

// MARK: - Bezier cubic splines
//public extension Float {
//    
//    func cubicBesierFunction(c1:float2, c2:float2) -> Float{
//        
//        let x = self
//        
//        let x0a:Float = 0
//        let y0a:Float = 0
//        let x3a:Float = 1
//        let y3a:Float = 1
//        
//        let x1a:Float = c1.x
//        let y1a:Float = c1.y
//        let x2a:Float = c2.x
//        let y2a:Float = c2.y
//        
//        let A =   x3a - 3*x2a + 3*x1a - x0a
//        let B = 3*x2a - 6*x1a + 3*x0a
//        let C = 3*x1a - 3*x0a
//        let D =   x0a
//        
//        let E =   y3a - 3*y2a + 3*y1a - y0a
//        let F = 3*y2a - 6*y1a + 3*y0a
//        let G = 3*y1a - 3*y0a
//        let H =   y0a
//        
//        var currentt = x
//        let nRefinementIterations = 5
//        
//        for _ in 0..<nRefinementIterations{
//            let currentx = valueFromT (t: currentt, A:A, B:B, C:C, D:D)
//            currentt -= (currentx - x)*(slopeFromT (t: currentt, A: A,B: B,C: C));
//        }
//        
//        let y = valueFromT (t: currentt,  A:E, B:F , C:G, D:H)
//        
//        return (y.isInfinite) ? 1 : (y.isFinite) ? y : 0
//    }
//    
//    func slopeFromT (t:Float, A:Float, B:Float, C:Float) -> Float {
//        return 1.0/(3.0*A*t*t + 2.0*B*t + C)
//    }
//    
//    func valueFromT (t:Float, A:Float, B:Float, C:Float, D:Float) -> Float {
//        return  A*(t*t*t) + B*(t*t) + C*t + D
//    }
//}
//
//public extension Collection where Iterator.Element == Float {
//    
//    public func cubicBezierSpline(controls:[float2])-> [Float]{
//        var curve = [Float]()
//        for x in self {
//            curve.append(x.cubicBesierFunction(c1: controls[0], c2: controls[1]))
//        }
//        return curve
//    }
//    
//    public func cubicBezierSpline(c1:float2, c2:float2)-> [Float]{
//        var curve = [Float]()
//        for x in self {
//            curve.append(x.cubicBesierFunction(c1: c1, c2: c2))
//        }
//        return curve
//    }
//}
//
