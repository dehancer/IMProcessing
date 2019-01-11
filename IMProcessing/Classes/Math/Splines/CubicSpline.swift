//
//  CubicSpline.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 14.04.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd
import Accelerate

// MARK: - Cubic Splines
//public extension Collection where Iterator.Element == Float {
//    
//    ///  Create 1D piecewise cubic spline curve from linear collection of x-Float points with certain control points
//    ///
//    ///  - parameter controls: list of (x,y) control points
//    ///
//    ///  - returns: interpolated list of (y) points
//    public func cubicSpline(controls:[float2], scale:Float=0)-> [Float]{
//        var curve = [Float]()
//        let max   = self.max()!
//        let S = splineSlopes(points: controls)
//        for i in self{
//            let x = Float(i)
//            var y = evaluateSpline(x: x, points: controls, slopes: S)
//            y = y<0 ? 0 : y > max ? max : y
//            var point = y
//            if scale > 0 {
//                point = point/(max/scale)
//            }
//            curve.append(point)
//        }
//        return curve
//    }
//    
//    ///  Create 2D piecewise cubic spline curve from linear collection of x-Float points with certain control points
//    ///
//    ///  - parameter controls: list of (x,y) control points
//    ///
//    ///  - returns: interpolated list of (x,y) points
//    public func cubicSpline(controls:[float2], scale:Float=0)-> [float2]{
//        var curve = [float2]()
//        let max   = self.max()!
//        let S = splineSlopes(points: controls)
//        for i in self{
//            let x = Float(i)
//            var y = evaluateSpline(x: x, points: controls, slopes: S)
//            y = y<0 ? 0 : y > max ? max : y
//            var point = float2(x,y)
//            if scale > 0 {
//                let s = max/scale
//                point = float2(point.x/s,point.y/s)
//            }
//            curve.append(point)
//        }
//        return curve
//    }
//    
//    
//    fileprivate func splineSlopes(points:[float2]) -> [Float] {
//        
//        // This code computes the unique curve such that:
//        //		It is C0, C1, and C2 continuous
//        //		The second derivative is zero at the end points
//        
//        let count = points.count
//        
//        var Y = [Float](repeating: 0, count: count)
//        var X = [Float](repeating: 0, count: count)
//        
//        var S = [Float](repeating: 0, count: count)
//        var E = [Float](repeating: 0, count: count)
//        var F = [Float](repeating: 0, count: count)
//        var G = [Float](repeating: 0, count: count)
//        
//        for i in 0 ..< count {
//            X[i]=points[i].x
//            Y[i]=points[i].y
//        }
//        
//        
//        let start = 0
//        let end   = count
//        
//        var A =  X [start+1] - X [start]
//        var B = (Y [start+1] - Y [start]) / A
//        
//        S [start] = B
//        
//        // Slopes here are a weighted average of the slopes
//        // to each of the adjcent control points.
//        
//        for j in (start + 2)  ..< end {
//            
//            let C =  X[j] - X[j-1]
//            let D = (Y[j] - Y[j-1]) / C
//            
//            S [j-1] = ((B * C + D * A) / (A + C))
//            
//            A = C
//            B = D
//        }
//        
//        S [end-1] = 2.0 * B - S[end-2]
//        S [start] = 2.0 * S[start] - S[start+1]
//        
//        if (end - start) > 2 {
//            
//            F [start] = 0.5
//            E [end-1] = 0.5
//            G [start] = 0.75 * (S [start] + S [start+1])
//            G [end-1] = 0.75 * (S [end-2] + S [end-1])
//            
//            for j in (start+1) ..< (end-1) {
//                
//                A = (X [j+1] - X [j-1]) * 2.0
//                
//                E [j] = (X [j+1] - X [j]) / A
//                F [j] = (X [j] - X [j-1]) / A
//                G [j] = 1.5 * S [j]
//                
//            }
//            
//            for j in (start+1) ..< end {
//                
//                A = 1.0 - F [j-1] * E [j]
//                
//                if j != end-1 { F [j] = F[j]/A }
//                
//                G [j] = (G [j] - G [j-1] * E [j]) / A
//                
//            }
//            
//            for j in stride(from:(end - 2), through: start, by: -1){
//                G [j] = G [j] - F [j] * G [j+1]
//            }
//            
//            for j in start ..< end {
//                S [j] = G [j]
//            }
//        }
//        
//        return S
//    }
//    
//    fileprivate func evaluateSpline(x:Float, points:[float2], slopes S:[Float]) -> Float {
//        
//        let count = points.count
//        
//        // Check for off each end of point list.
//        
//        if x <= points[0].x       { return points[0].y }
//        
//        if x >= points[count-1].x { return points[count-1].y }
//        
//        // Binary search for the index.
//        
//        var lower = 1
//        var upper = count - 1
//        
//        while upper > lower {
//            
//            let mid = (lower + upper) >> 1
//            
//            let point = points[mid]
//            
//            if x == point.x { return point.y }
//            
//            if x > point.x { lower = mid + 1 }
//            else           { upper = mid }
//            
//        }
//        
//        let j = lower
//        
//        // X [j - 1] < x <= X [j]
//        // A is the distance between the X [j] and X [j - 1]
//        // B and C describe the fractional distance to either side. B + C = 1.
//        
//        // We compute a cubic spline between the two points with slopes
//        // S[j-1] and S[j] at either end. Specifically, we compute the 1-D Bezier
//        // with control values:
//        //
//        //		Y[j-1], Y[j-1] + S[j-1]*A, Y[j]-S[j]*A, Y[j]
//        
//        let P0 = points[j-1]
//        let P1 = points[j]
//        let S0 = S[j-1]
//        let S1 = S[j]
//        return evaluateSplineSegment (x,
//                                      P0.x,
//                                      P0.y,
//                                      S0,
//                                      P1.x,
//                                      P1.y,
//                                      S1)
//    }
//    
//    fileprivate func evaluateSplineSegment (_ x:Float,
//                                _ x0:Float,
//                                _ y0:Float,
//                                _ s0:Float,
//                                _ x1:Float,
//                                _ y1:Float,
//                                _ s1:Float) -> Float
//    {
//        
//        let A = x1 - x0
//        
//        let B = (x - x0) / A
//        
//        let C = (x1 - x) / A
//        
//        let D = ((y0 * (2.0 - C + B) + (s0 * A * B)) * (C * C)) +
//            ((y1 * (2.0 - B + C) - (s1 * A * C)) * (B * B));
//        
//        return D
//    }
//}
//
//
//// MARK: - 3D Cubic piecewise surface spline
//public extension Collection where Iterator.Element == [Float] {
//    
////    public func cubicSpline(surface controlPoints:IMPSurfaceMatrix, scale:Float=0)  -> [Float]{
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
////            let spline = yPoints.cubicSpline(controls: points, scale: 0) as [Float]
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
////            let spline = xPoints.cubicSpline(controls: points, scale: 0) as [Float]
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
