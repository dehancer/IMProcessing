//: [Previous](@previous)

import Foundation
import simd
import Accelerate

var str = "Hello, playground"

//: [Next](@next)


var f:[Float] = [0,0,0,10,0,0,0,0,0]
var b:[Float] = [0,1,2,3,4,5,6,7,8]
var o = [Float](repeating:0, count:8)

var s = stride(from: Float(0), through: 1, by: Float(1)/Float(f.count-1))

var i = 0
for x in s {
    print("x[\(i)]  = \(x)")
    i += 1
}


vDSP_vlint(f, b, 1, &o, 1, vDSP_Length(f.count), vDSP_Length(b.count))
print(o)

var sb:Float = 1
vDSP_vsimps(f, 1, &sb, &o, 1, vDSP_Length(b.count))

print(o)

sb = 1
vDSP_vtrapz(f, 1, &sb, &o, 1, vDSP_Length(b.count))

print(o)


//
//
//dot(float2(1), float2(0.5))
//
//func lum(_ c:float2) -> Float {
//    return dot(c, float2(0.5))
//}
//
//func clipcolor(_ c:float2) -> float2 {
//    
//    var c = c
//    
//    let l = lum(c)
//    let n = min(c.x, c.y)
//    let x = max(c.x, c.y)
//    
//    if (n < 0.0) {
//        c.x = l + ((c.x - l) * l) / (l - n)
//        c.y = l + ((c.y - l) * l) / (l - n)
//    }
//    if (x > 1.0) {
//        c.x = l + ((c.x - l) * (1.0 - l)) / (x - l)
//        c.y = l + ((c.y - l) * (1.0 - l)) / (x - l)
//    }
//    
//    return c
//}
//
//
//func setlum(_ c:float2, _ l:Float) ->float2 {
//    var c = c
//    let d = l - lum(c)
//    c = c + float2(d)
//    return clipcolor(c)
//}
//
//
//func blend(base:float2, overlay:float2) -> float2 {
//    return base * float2(1.0 - overlay.y) + setlum(base, lum(overlay)) * float2(overlay.y)
//}
//
////func blendLuminosity(base:float2, overlay:float2) {
////    return base.x * (1.0 - overlay.y) + setlum(base.x, overlay.x) * overlay.y
////}
//
////func blendLuminosity(base:float2, overlay:float2) -> Float {
////    return base.x * (1.0 - overlay.y) + setlum(base, lum(overlay)) * overlay.y
////}
//
//
//var controls = [float3(50,0,0),  float3(20,1,1), float3(30,50,256),  float3(70,0,256), float3(10,22,256), float3(11,24,256)]
//
//func tps(controls:[float3]){
//}
//
//let cmrM = float4x4(rows: [
//    float4(-1, 3,-3, 1),
//    float4( 2,-5, 4,-1),
//    float4(-1, 0, 1, 0),
//    float4( 0, 2, 0, 0),
//    ])
//
//
//// Q(u,v) = (u^3,u^2,u,1)B[P]B(v^3,v^2,v,1)
//
//let x:Float = 1
//let y:Float = 1
//
//let tu = 0.5 * float4(powf(x, 3), powf(x, 2), x, 1)
//let tv = 0.5 * float4(powf(y, 3), powf(y, 2), y, 1)
//
//let u = float4(10,5,64,10)
//let v = float4(100,100,64,10)
//
//let tens1 = float2x4([u,float4(0)])
//let tens2 = float2x4([v,float4(0)])
//
//let left  = tu*cmrM
//let right = tv*cmrM
//
//let lt = left*u
//let rt = right*v
//
//let f = lt*rt
//(f.x+f.y)/2
//
//dot(lt,rt)
//
//let f1 = dot(tu*cmrM,u)
//let f2 = dot(tv*cmrM,v)
//
//
//sqrt(f1*f1+f2*f2)
//(f1+f2)/2
//
//
////dot(left,right)
