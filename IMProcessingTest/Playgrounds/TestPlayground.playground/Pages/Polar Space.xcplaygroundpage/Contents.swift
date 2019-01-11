//: Playground - noun: a place where people can play

import Cocoa
import Metal
import simd

let v = float2(12.9233)
fract(v)
floor(v)

func polarSquare(radius:Float,theta:Float) -> Float {
    let n:Float  = 4
    let f  = theta
    let pi = Float.pi
    let nfpi = n * f / pi
    let z  = floor(0.5 * floor(nfpi))
    let x  = 2 * pi / n * (0.5 * floor(nfpi) - z) - f
    let y  = pi/n*floor(n*f/pi)
    return radius/cos(x+y)
}

for f in 0..<100 {
    let r = polarSquare(radius: Float(100), theta: Float(f) * 2 * Float.pi / 180)
}


for f in 0..<100 {
    let r = polarSquare(radius: Float(20), theta: Float(f) * 2 * Float.pi / 180)
}


//var str = "Hello, playground"
//
//var a = [1,2,3,4,34,4,56,13,34,5,6,6,6]
//
//a.count.toIntMax()
//
//a.indices.count.toIntMax()
//
//
//MemoryLayout.size(ofValue: a) * Int(a.count.toIntMax())
//
//let dev = MTLCreateSystemDefaultDevice()
//let d = dev?.maxThreadsPerThreadgroup
//
//print(d)
//
//
//var bits = 0b0000
//
//bits |= 0b0001
//bits |= 0b0010
//bits |= 0b0100
//bits |= 0b1000
//
//(((bits % 0b1111) == 0) && bits>0)
//
//let PassportCC24:[[float3]] = [
//    [
//        float3(115,82,68),   // dark skin
//        float3(194,150,130), // light skin
//        float3(98,122,157),  // blue sky
//        float3(87,108,67),   // foliage
//        float3(133,128,177), // blue flower
//        float3(103,189,170)  // bluish flower
//    ],
//    
//    [
//        float3(214,126,44), // orange
//        float3(80,91,166),  // purplish blue
//        float3(193,90,99),  // moderate red
//        float3(94,60,108),  // purple
//        float3(157,188,64), // yellow green
//        float3(224,163,46)  // orange yellow
//    ],
//    
//    [
//        float3(56,61,150),  // blue
//        float3(79,148,73),  // green
//        float3(175,54,60),  // red
//        float3(231,199,31), // yellow
//        float3(187,86,149), // magenta
//        float3(8,133,161),  // cyan
//    ],
//    
//    [
//        float3(243,243,242), // white
//        float3(200,200,200), // neutral 8
//        float3(160,160,160), // neutral 6,5
//        float3(122,122,121), // neutral 5
//        float3(85,85,85),    // neutral 3.5
//        float3(52,52,52)     // black
//    ]
//]
//
//print(PassportCC24)
//print(PassportCC24.count,PassportCC24[0].count)
//
