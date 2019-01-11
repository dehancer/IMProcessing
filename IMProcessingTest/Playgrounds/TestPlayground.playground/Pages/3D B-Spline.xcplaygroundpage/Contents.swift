//: [Previous](@previous)

import Foundation
import simd

var str = "Hello, playground"

//: [Next](@next)


//protocol NumericType: Comparable {
//    static func +(lhs: Self, rhs: Self) -> Self
//    static func -(lhs: Self, rhs: Self) -> Self
//    static func *(lhs: Self, rhs: Self) -> Self
//    static func /(lhs: Self, rhs: Self) -> Self
//    static func %(lhs: Self, rhs: Self) -> Self
//    init(_ v: Int)
//}
//
//extension Double : NumericType {}
//extension Float  : NumericType {}
//extension Int    : NumericType {}
//extension Int8   : NumericType {}
//extension Int16  : NumericType {}
//extension Int32  : NumericType {}
//extension Int64  : NumericType {}
//extension UInt   : NumericType {}
//extension UInt8  : NumericType {}
//extension UInt16 : NumericType {}
//extension UInt32 : NumericType {}
//extension UInt64 : NumericType {}
//
//
//protocol Subscriptable{
//    subscript(index: Int) -> Self {get set}
//}
//
////extension int3   : Subscriptable{}
////extension uint3  : Subscriptable{}
////extension float3 : Subscriptable{}
////extension double3: Subscriptable{}
//

//
// Source: http://paulbourke.net/geometry/spline/
//

/*
 This returns the point "output" on the spline curve.
 The parameter "v" indicates the position, it ranges from 0 to n-t+2
 
 */
private func bSplinePoint(_ controls:[float3], _ u:[Int], _ t:Int, _ v:Float, _ output: inout float3) {
    
    output.x = 0
    output.y = 0
    output.z = 0
    
    for k in 0..<controls.count {
        let b = bSplineBlend(k, t, u, v)
        output.x += controls[k].x * b
        output.y += controls[k].y * b
        output.z += controls[k].z * b
    }
}


/*
 Calculate the blending value, this is done recursively.
 
 If the numerator and denominator are 0 the expression is 0.
 If the deonimator is 0 the expression is 0
 */
private func bSplineBlend(_ k:Int, _ t:Int, _ u:[Int], _ v:Float) -> Float {
    var value:Float
    
    if (t == 1) {
        
        if ((Float(u[k]) <= v) && (v < Float(u[k+1]))) { value = 1 }
        
        else { value = 0 }
        
    } else {
        
        if ((u[k+t-1] == u[k]) && (u[k+t] == u[k+1])) { value = 0 }
            
        else if (u[k+t-1] == u[k]) {
            
            value = (Float(u[k+t]) - v) / Float(u[k+t] - u[k+1]) * bSplineBlend(k+1,t-1,u,v)
            
        }
        else if (u[k+t] == u[k+1]) {
            
            value = (v - Float(u[k])) / Float(u[k+t-1] - u[k]) * bSplineBlend(k,t-1,u,v)
            
        }
        else{
            
            value = (v - Float(u[k])) / Float(u[k+t-1] - u[k]) * bSplineBlend(k,t-1,u,v) +
                (Float(u[k+t]) - v) / Float(u[k+t] - u[k+1]) * bSplineBlend(k+1,t-1,u,v)
            
        }
    }
    return value
}

/*
 The positions of the subintervals of v and breakpoints, the position
 on the curve are called knots. Breakpoints can be uniformly defined
 by setting u[j] = j, a more useful series of breakpoints are defined
 by the function below. This set of breakpoints localises changes to
 the vicinity of the control point being modified.
 */
private func bSplineKnots(_ count:Int, degree t:Int) -> [Int] {
    let n = count - 1
    let knots = n + t + 1
    var u = [Int](repeating:0, count:knots)
    for j in 0..<knots {
        if (j < t)       { u[j] = 0 }
        else if (j <= n) { u[j] = j - t + 1}
        else if (j > n ) { u[j] = n - t + 2}
    }
    return u
}


/*-------------------------------------------------------------------------
 Create all the points along a spline curve
 @controls - control points
 @resolution - curve resolution
 @degree - t
 @return curve with "resolution" of them.
 */
public func bSpline3D(controls:[float3], resolution count:Int, degree t:Int = 3)-> [float3]{
    var curve = [float3](repeating:float3(0), count:count)
    
    let n = controls.count - 1
    let knots = bSplineKnots(controls.count, degree: t)
    
    var interval:Float = 0
    let increment:Float = Float(n - t + 2)/Float(count - 1)
    
    for i in 0..<count-1 {
        
        bSplinePoint(controls, knots, t, interval, &curve[i])
        interval += increment
    }
    
    curve[count-1] = controls[n]
    
    return curve
}


var controls = [float3(0,0,0),   float3(50,50,256),   float3(20,1,1),   float3(256,0,256)]

var spline = bSpline3D(controls: controls, resolution: 20)

for s in spline {
    let s = s
    print(s)
}
