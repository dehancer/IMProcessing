//: [Previous](@previous)

//: [Next](@next)

import Foundation
import Accelerate
import simd

// MARK: - Catmull-Rom piecewise splines
class CatmulRomWeights {
    
    static let cmrM = float4x4(rows: [
        float4(-1, 3,-3, 1),
        float4( 2,-5, 4,-1),
        float4(-1, 0, 1, 0),
        float4( 0, 2, 0, 0),
        ])
    
    var controlStep:Float {
        return 1/Float(controls.count)
    }
    
    var controls:[float3]
    
    init(controls:[float3]){
        self.controls = controls
    }
    
    static func interpolate1D(at t:Float, controls:float4) -> Float {
        let n = 0.5 * float4(powf(t, 3), powf(t, 2), t, 1) * CatmulRomWeights.cmrM
        return dot(n,controls)
    }
    
    func bounds(at t:Float) -> Int {
        return bounds(at: Int(t/controlStep))
    }
    
    func bounds(at t:Int) -> Int {
        return t <= 0 ? 0 :  t >= (controls.count-1) ? controls.count - 1 : t
    }
    
    func tanget(_ xi:Int, _ t:Float) -> Float {
        return (t-controlStep * Float(xi))/controlStep
    }

    func points(at t:Float, index:Int) -> (Float,float4) {
        let xi = bounds(at: t)
        
        let xi0 = bounds(at: xi-1)
        let xi1 = bounds(at: xi)
        let xi2 = bounds(at: xi+1)
        let xi3 = bounds(at: xi+2)
        
        let lt = tanget(xi, t)
        
        let sorted = controls //.sorted { return $0[index]<$1[index] }
        
        return (lt,float4(
            sorted[xi0][index],
            sorted[xi1][index],
            sorted[xi2][index],
            sorted[xi3][index]
        ))
    }
    
    func splinePoint(at t:float3) -> float3 {
        
        let (xt,xp) = points(at: t.x, index: 0)
        let x = CatmulRomWeights.interpolate1D(at: xt, controls:xp)

        let (yt,yp) = points(at: t.y, index: 1)
        let y = CatmulRomWeights.interpolate1D(at: yt, controls:yp)

        let (zt,zp) = points(at: t.z, index: 2)
        let z = CatmulRomWeights.interpolate1D(at: zt, controls:zp)
        
        
        return float3(x,y,z)
    }
}

let range = [[0,10,20,30,40,50,60,70,80,90,100],[0,10,20,30,40,50,60,70,80,90,100]]
var controls = [float3(50,0,0),  float3(20,1,1), float3(30,50,256),  float3(70,0,256), float3(10,22,256), float3(11,24,256)]

var m = CatmulRomWeights.interpolate1D(at: 0.2, controls: float4(0,1,2,4))

var cms = CatmulRomWeights(controls: controls)
var s = cms.splinePoint(at: float3(0.5,0.1,0.5))

for x in stride(from: 0, to: Float(1), by: Float(0.01)) {
    let s = cms.splinePoint(at: float3(x,x,0)).z
}

