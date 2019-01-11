//
//  IMPInterpolator.swift
//  Pods
//
//  Created by Denis Svinarchuk on 02/05/2017.
//
//

import Foundation
import simd
import Accelerate


public protocol IMPInterpolator{
    
    typealias Bounds = (left:float2,right:float2)
    
    var minimumControls:Int {get}
    var controls:[float2] {get set}
    var resolution:Int {get}
    var bounds:Bounds {get set}
    init(resolution:Int)
    func value(at x:Float) -> Float
}

public extension IMPInterpolator {
    
    public subscript(_ t: Float) -> Float {
        return value(at: t)
    }
    
    public var step:Float {
        return 1/Float(resolution)
    }
        
    public func testBounds(at x:Float) -> Float? {
        if bounds.left.x>=x { return bounds.left.y }
        if bounds.right.x<=x { return bounds.right.y }
        return nil
    }
    
    public func controlIndices(at x: Float) -> (i1:Int,i2:Int)? {
        return Self.indices(of:controls, at: x)
    }
    
    public static func linear(of spline:[float2], at x:Float) -> Float {
        guard let (k1,k2) = Self.indices(of:spline, at: x) else {return x}

        let P0 = spline[k1]
        let P1 = spline[k2]
        
        let d = P1.x - P0.x
        let x = d == 0 ? 0 : (x-P0.x)/d
        
        return P0.y + (P1.y-P0.y)*x
    }
    
    public static func indices(of spline:[float2], at x: Float) -> (i1:Int,i2:Int)? {
        var k = (0,spline.count-1)
        while k.1-k.0 > 1 {
            let i = floor(Float(k.1+k.0)/2.0).int
            if spline[i].x > x { k.1 = i }
            else                 { k.0 = i }
        }
        return k
    }
}

public class IMPLinearInterpolator : IMPInterpolator {

    public var bounds:(left:float2,right:float2) = (float2(0), float2(1))

    public var minimumControls:Int {return 1}
    
    public let resolution: Int
    
    public var controls = [float2]()
    
    public required init(resolution:Int) {
        self.resolution = resolution
    }
    
    public func value(at x: Float) -> Float {
        if let y = testBounds(at: x) { return y }
        guard controls.count > minimumControls else { return x }

        return IMPLinearInterpolator.linear(of: controls, at: x)
    }
}


//public protocol IMPInterpolator{
//    
//    var controls:[Float] {get}
//    var interval:Float {get}
//    
//    init(controls points:[Float])
//    func value(at t:Float) -> Float
//}
//
//public extension IMPInterpolator {
//    
//    public subscript(_ t: Float) -> Float {
//        return value(at: t)
//    }
//    
//    public func bounds(at t:Float) -> Int {
//        return bounds(at: Int(t/interval))
//    }
//    
//    public func bounds(at t:Int) -> Int {
//        return t <= 0 ? 0 :  t >= (controls.count-1) ? controls.count - 1 : t
//    }
//}
//
//
////public class IMPLinearInterpolator : IMPInterpolator {
////    public var controls: [Float]
////    
////    public required init(controls points: [Float]) {
////        self.controls=points
////    }
////    
////    public var interval:Float {
////        return 1/Float(controls.count)
////    }
////    
////    public func value(at t: Float) -> Float {
////        let xi1 = bounds(at: t)
////        let xi0 = bounds(at: xi1-1)
////        return Float(1-t) * controls[xi0] + t*controls[xi1]
////    }
////}
//
//
//public class IMPCatmulRomSpline:IMPInterpolator {
//    
//    public static let baseMatrix = float4x4(rows: [
//        float4(-1, 3,-3, 1),
//        float4( 2,-5, 4,-1),
//        float4(-1, 0, 1, 0),
//        float4( 0, 2, 0, 0),
//        ])
//    
//    public  var controls:[Float]
//    
//    public var interval:Float {
//        return 1/Float(controls.count)
//    }
//    
//    public required init(controls points: [Float]) {
//        self.controls = points
//    }
//    
//    private static func interpolate(at t:Float, controls:float4) -> Float {
//        let n = 0.5 * float4(powf(t, 3), powf(t, 2), t, 1) * IMPCatmulRomSpline.baseMatrix
//        return dot(n,controls)
//    }
//    
//    private func tanget(_ xi:Int, _ t:Float) -> Float {
//        return (t-interval * Float(xi))/interval
//    }
//    
//    private func points(at t:Float) -> (Float,float4) {
//        let xi = bounds(at: t)
//        
//        let xi0 = bounds(at: xi-1)
//        let xi1 = bounds(at: xi)
//        let xi2 = bounds(at: xi+1)
//        let xi3 = bounds(at: xi+2)
//        
//        let lt = tanget(xi, t)
//        
//        return (lt,float4(
//            controls[xi0],
//            controls[xi1],
//            controls[xi2],
//            controls[xi3]
//        ))
//    }
//    
//    public func value(at t: Float) -> Float {
//        let (xt,xp) = points(at: t)
//        return IMPCatmulRomSpline.interpolate(at: xt, controls:xp)
//    }
//}
//
//public class IMPCubicSpline: IMPInterpolator {
//    
//    public func value(at t: Float) -> Float {
//        return evaluateSpline(x: t, points: cubicControls, slopes: slops)
//    }
//    
//    public var controls: [Float]
//    private var cubicControls: [float2]
//    
//    public var interval: Float {
//        return Float(1)/Float(controls.count-1)
//    }
//    
//    private lazy var slops:[Float] = self.splineSlopes(controls: self.cubicControls)
//    
//    public required init(controls points: [Float]) {
//        controls = points
//        cubicControls = [float2]()
//        var i = 0
//        for x in stride(from: Float(0), through: 1, by: interval) {
//            self.cubicControls.append(float2(x,controls[i]))
//            i += 1
//        }
//    }
//    
//    private func evaluateSpline(x:Float, points:[float2], slopes S:[Float]) -> Float {
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
//    private func evaluateSplineSegment (_ x:Float,
//                                        _ x0:Float,
//                                        _ y0:Float,
//                                        _ s0:Float,
//                                        _ x1:Float,
//                                        _ y1:Float,
//                                        _ s1:Float) -> Float
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
//    
//    private func splineSlopes(controls points:[float2]) -> [Float] {
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
//}
//
//public class IMPBSpline: IMPInterpolator {
//    
//    public let degree:Int = 3
//    public var controls: [Float]
//    
//    private lazy var knots:[Int] = self.bSplineKnots(self.controls.count, degree: self.degree)
//    public required init(controls points: [Float]) {
//        self.controls=points
//    }
//    
//    public var interval: Float {
//        return Float(1)/Float(controls.count-1)
//    }
//    
//    public func value(at t: Float) -> Float {
//        return   bSplinePoint(controls, knots, degree, Float(controls.count-1-degree+2) * t)
//    }
//    
//    //
//    // Source: http://paulbourke.net/geometry/spline/
//    //
//    
//    /*
//     This returns the point "output" on the spline curve.
//     The parameter "v" indicates the position, it ranges from 0 to n-t+2
//     
//     */
//    private func bSplinePoint(_ controls:[Float], _ u:[Int], _ t:Int, _ v:Float) -> Float {
//        
//        var output:Float = 0
//        for k in 0..<controls.count {
//            let b = bSplineBlend(k, t, u, v)
//            output += controls[k] * b
//        }
//        return output
//    }
//    
//    /*
//     Calculate the blending value, this is done recursively.
//     
//     If the numerator and denominator are 0 the expression is 0.
//     If the deonimator is 0 the expression is 0
//     */
//    private func bSplineBlend(_ k:Int, _ t:Int, _ u:[Int], _ v:Float) -> Float {
//        var value:Float
//        
//        if (t == 1) {
//            
//            if ((Float(u[k]) <= v) && (v < Float(u[k+1]))) { value = 1 }
//                
//            else { value = 0 }
//            
//        } else {
//            
//            if ((u[k+t-1] == u[k]) && (u[k+t] == u[k+1])) { value = 0 }
//                
//            else if (u[k+t-1] == u[k]) {
//                
//                value = (Float(u[k+t]) - v) / Float(u[k+t] - u[k+1]) * bSplineBlend(k+1,t-1,u,v)
//                
//            }
//            else if (u[k+t] == u[k+1]) {
//                
//                value = (v - Float(u[k])) / Float(u[k+t-1] - u[k]) * bSplineBlend(k,t-1,u,v)
//                
//            }
//            else{
//                
//                value = (v - Float(u[k])) / Float(u[k+t-1] - u[k]) * bSplineBlend(k,t-1,u,v) +
//                    (Float(u[k+t]) - v) / Float(u[k+t] - u[k+1]) * bSplineBlend(k+1,t-1,u,v)
//                
//            }
//        }
//        return value
//    }
//    
//    /*
//     The positions of the subintervals of v and breakpoints, the position
//     on the curve are called knots. Breakpoints can be uniformly defined
//     by setting u[j] = j, a more useful series of breakpoints are defined
//     by the function below. This set of breakpoints localises changes to
//     the vicinity of the control point being modified.
//     */
//    private func bSplineKnots(_ count:Int, degree t:Int) -> [Int] {
//        let n = count - 1
//        let knots = n + t + 1
//        var u = [Int](repeating:0, count:knots)
//        for j in 0..<knots {
//            if (j < t)       { u[j] = 0 }
//            else if (j <= n) { u[j] = j - t + 1}
//            else if (j > n ) { u[j] = n - t + 2}
//        }
//        return u
//    }
//}
