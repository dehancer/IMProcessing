//
//  IMPMatrixBasedSpline.swift
//  Pods
//
//  Created by denis svinarchuk on 25.06.17.
//
//

import Foundation
import Surge
import simd

open class IMPMatrixBasedSpline:IMPInterpolator{
    
    public var bounds:(left:float2,right:float2) = (float2(0), float2(1)) { didSet{  didControlsUpdate() } }

    open var minimumControls:Int {return 4}
    
    open var controls = [float2]() { didSet{  didControlsUpdate() } }
    
    public func didControlsUpdate() {
        guard controls.count >= minimumControls else { return }
        nps = getNps()
        curve = evaluate()
    }
    
    public let resolution: Int
    
    public func value(at x: Float) -> Float {
        guard controls.count >= minimumControls else { return x }
        if let y = testBounds(at: x) { return y }
        return IMPMatrixBasedSpline.linear(of: curve, at: x)
    }
    
    open var matrix:float4x4 { return float4x4(diagonal:float4(1)) }
    
    public required init(resolution:Int) {
        self.resolution = resolution
    }
    
    private var curve = [float2]()
    
    private var cpn:Int {return controls.count }
    
    //
    // interval numbers
    //
    private var ni:Int { return cpn-(minimumControls-1) }
    
    private var n:Int {return resolution }
    
    //
    // Points in every intervals between 1 and n-1
    //
    private var npf:Int {return n/ni}
    
    //
    // Points in the last interval
    //
    private var npl:Int {return n - (npf * (ni - 1)) }
    
    private var nps = [Int]()
    
    private func getNps() -> [Int] {
        var v = [Int](repeating:npf+1, count:ni-1)
        v.append(npl+1)
        v[0] -= 1
        return v
    }
    
    private func evaluate() -> [float2] {
        var ii = 0
        var linear = [float2]()
        for i in 1..<cpn-(minimumControls-2){
            let p0 = controls[i-1]
            let p1 = controls[i-0]
            let p2 = controls[i+1]
            let p3 = controls[i+2]
            let px = float4(p0.x,p1.x,p2.x,p3.x)
            let py = float4(p0.y,p1.y,p2.y,p3.y)
            var s = spline(x: px, y: py, np: nps[ii])
            if ii > 0 {
                s.remove(at: 0)
            }
            ii += 1
            linear.append(contentsOf: s)
        }
        
        return linear
    }
    
    private func spline(x:float4,y:float4,np:Int) -> [float2] {
        let u  = linspace(Float(0), Float(1), num: np)
        let u2 = u*u
        let u3 = u2*u
        var s = [float2]()
        for n in 0..<np {
            let t  = float4(1,u[n],u2[n],u3[n])
            let tm = t * matrix
            s.append(float2(dot(tm,x),dot(tm,y)))
        }
        return s
    }
}
