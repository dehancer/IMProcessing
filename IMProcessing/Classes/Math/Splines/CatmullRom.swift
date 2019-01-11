//
//  CatmullRom.swift
//  IMPPatchDetectorTest
//
//  Created by denis svinarchuk on 14.04.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Accelerate

// MARK: - Catmull-Rom piecewise splines
//public extension Collection where Iterator.Element == Float {
//    
//    ///  Create 1D piecewise Catmull-Rom spline curve from linear collection of x-Float points with certain control points
//    ///
//    ///  - parameter controls: list of (x,y) control points
//    ///
//    ///  - returns: interpolated list of (y) points
//    public func catmullRomSpline(controls points:[float2], scale:Float=0) -> [Float]{
//        var curve = [Float]()
//        for x in self {
//            curve.append(catmullRomSplinePoint(x: x, points: points).y)
//        }
//        if scale>0 {
//            var max:Float = 0
//            vDSP_maxv(curve, 1, &max, vDSP_Length(curve.count))
//            max = scale/max
//            vDSP_vsmul(curve, 1, &max, &curve, 1, vDSP_Length(curve.count))
//        }
//        return curve
//    }
//    
//    ///  Create 2D piecewise Catmull-Rom spline curve from linear collection of x-Float points with certain control points
//    ///
//    ///  - parameter controls: list of (x,y) control points
//    ///
//    ///  - returns: interpolated list of (x,y) points
//    public func catmullRomSpline(controls points:[float2], scale:Float=0) -> [float2]{
//        var curve = [float2]()
//        for x in self {
//            curve.append(catmullRomSplinePoint(x: x, points: points))
//        }
//        if scale>0 {
//            var max:Float = 0
//            let pointer = OpaquePointer(curve)
//            let address = UnsafeMutablePointer<Float>(pointer)
//            vDSP_maxv(address + 1, 2, &max, vDSP_Length(curve.count))
//            max = scale/max
//            vDSP_vsmul(address, 1, &max, address, 1, vDSP_Length(curve.count*2))
//        }
//        return curve
//    }
//    
//    fileprivate func catmullRomSplinePoint(x:Float,points:[float2]) -> float2 {
//        let Xi = x
//        
//        let k  = find(points, Xi: Xi)
//        let P1 = points[k.0]
//        let P2 = points[k.1]
//        
//        let (a,b,h) = catmullRomSplineCoeff(k: k, points: points)
//        
//        let t = (Xi - P1.x) / h
//        let t2 = t*t
//        let t3 = t2*t
//        
//        let h00 =  2*t3 - 3*t2 + 1
//        let h10 =    t3 - 2*t2 + t
//        let h01 = -2*t3 + 3*t2
//        let h11 =    t3 - t2
//        
//        return float2(
//            Xi,
//            h00 * P1.y + h10 * h * a + h01 * P2.y + h11 * h * b
//        )
//    }
//    
//    fileprivate func find(_ points:[float2], Xi:Float)->(Int,Int){
//        let n = points.count
//        
//        var k1:Int = 0
//        var k2:Int = n-1
//        while k2-k1 > 1 {
//            let k = floor(Float(k2+k1)/2.0).int
//            let xkpoint = points[k]
//            if xkpoint.x > Xi {
//                k2 = k
//            }
//            else {
//                k1 = k
//            }
//        }
//        return (k1,k2)
//    }
//    
//    fileprivate func catmullRomSplineCoeff(k:(Int,Int), points:[float2]) -> (a:Float,b:Float,h:Float) {
//        
//        let P1 = points[k.0]
//        let P2 = points[k.1]
//        
//        let h = P2.x - P1.x
//        var a:Float = 0
//        var b:Float = 0
//        
//        if k.0 == 0 {
//            let P3 = points[k.1+1]
//            a = (P2.y - P1.y) / h
//            b = (P3.y - P1.y) / (P3.x - P1.x)
//        }
//        else if k.1 == points.count-1 {
//            let P0 = points[k.0-1]
//            a = (P2.y - P1.y) / (P2.x - P0.x)
//            b = (P2.y - P1.y) / h
//        }
//        else{
//            let P0 = points[k.0-1]
//            let P3 = points[k.1+1]
//            a = (P2.y - P0.y) / (P2.x - P0.x)
//            b = (P3.y - P1.y) / (P3.x - P1.x)
//        }
//        
//        return (a,b,h)
//    }
//}
//
//extension Collection where Iterator.Element == [Float] {
//    
//    public func catmullRomSpline(controls controlPoints:[float3], scale:Float=0)  -> [Float]{
//        
//        if self.count != 2 {
//            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
//        }
//        
//        var curve   = [Float]()
//        let xPoints = self[0 as! Self.Index]
//        let yPoints = self[count - 1 as! Self.Index]
//        
//        //
//        // y-z
//        //
//        var scontrols = controlPoints.sorted { $0.y<$1.y }
//        
//        var points = [float2]()
//        
//        for yi in 0 ..< scontrols.count {
//            let y = scontrols[yi].y
//            let z = scontrols[yi].z
//            points.append(float2(y,z))
//        }
//        
//        let ysplines = yPoints.catmullRomSpline(controls: points, scale: scale) as [Float]
//        
//        //
//        // x-y-z
//        //
//        
//        scontrols = controlPoints.sorted { $0.x<$1.x }
//        
//        points = [float2]()
//        
//        for xi in 0..<scontrols.count {
//            
//            let x = scontrols[xi].x
//            let z = scontrols[xi].z
//            
//            points.append(float2(x,z))
//        }
//        
//        let xsplines = xPoints.catmullRomSpline(controls: points, scale: scale) as [Float]
//        
//        for y in ysplines {
//            for x in xsplines{
//                curve.append(x*y)
//            }
//        }
//        return curve
//    }
//}
//
//// MARK: - 3D Catmull-Rom piecewise surface spline
//public extension Collection where Iterator.Element == [Float] {
//    
////    public func catmullRomSpline(surface controlPoints:IMPSurfaceMatrix, scale:Float=0)  -> [Float]{
////        
////        if self.count != 2 {
////            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
////        }
////        
////        var curve   = [Float]()
////        let xPoints = self[0 as! Self.Index]
////        let yPoints = self[count - 1 as! Self.Index]
////        
////        
////        //
////        // y-z
////        //
////        var ysplines = [Float]()
////        for i in 0 ..< controlPoints.columns.count {
////            
////            var points = [float2]()
////            
////            for yi in 0 ..< controlPoints.rows.count {
////                let y = controlPoints.rows[yi]
////                let z = controlPoints.row(yi)[i]
////                points.append(float2(y,z))
////            }
////            
////            let spline = yPoints.catmullRomSpline(controls: points, scale: 0) as [Float]
////            ysplines.append(contentsOf: spline)
////        }
////        
////        let z = IMPSurfaceMatrix(xy: [yPoints,controlPoints.columns], weights: ysplines)
////        
////        //
////        // x-y-z
////        //
////        for i in 0 ..< yPoints.count {
////            
////            var points = [float2]()
////            
////            for xi in 0 ..< controlPoints.columns.count {
////                let x = controlPoints.columns[xi]
////                let y = z.row(xi)[i]
////                points.append(float2(x,y))
////            }
////            let spline = xPoints.catmullRomSpline(controls: points, scale: 0) as [Float]
////            curve.append(contentsOf: spline)
////        }
////        
////        if scale>0 {
////            var max:Float = 0
////            vDSP_maxv(curve, 1, &max, vDSP_Length(curve.count))
////            max = scale/max
////            vDSP_vsmul(curve, 1, &max, &curve, 1, vDSP_Length(curve.count))
////        }
////        
////        return curve
////    }
//}
//
//
//
