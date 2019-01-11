//: [Previous](@previous)

import Foundation
import simd

public extension float2x2 {
    var determinant:Float {
        get {
            let t = cmatrix.columns
            return t.0.x*t.1.y - t.0.y*t.1.x
        }
    }
}

class IMPLineSegment:Equatable{
    
    public init(p0:float2,p1:float2){
        self.p0 = float2(p0.x,p0.y)
        self.p1 = float2(p1.x,p1.y)
    }
    
    public static func == (lhs: IMPLineSegment, rhs: IMPLineSegment) -> Bool {
        return lhs.p0.x == rhs.p0.x && lhs.p1.x == rhs.p1.x && lhs.p0.y == rhs.p0.y && lhs.p1.y == rhs.p1.y
    }
    
    public let p0:float2
    public let p1:float2
    
    public var standardForm:float3 {
        get {
            var f = float3()
            f.x =  p0.y-p1.y
            f.y =  p1.x-p0.x
            f.z = -(p0.x*p1.y - p1.x*p0.y)
            return f
        }
    }
    
    public func normalForm() -> float3 {
        let form  = standardForm
        let a = form.x
        let b = form.y
        let c = form.z
        let factor = sign(c) * (-1 / sqrt(a*a+b*b))
        
        return float3(a,b,c) * float3(factor)
    }

    public func scale(_ scale:float2) -> IMPLineSegment {
        return IMPLineSegment(p0: self.p0 * scale, p1: self.p1 * scale)
    }
    
    public func houghSpace(size:NSSize = NSSize(width:1,height:1)) -> float2 // x == rho, y == theta
    {
        //
        // top left style
        //
        let line = self.scale(float2(Float(size.width),Float(size.height)))
        let nf = line.normalForm() * float3(-1)
        var a  = acos(nf.x)
        let angle = a * 180 / Float.pi
        a = (angle >= 45 && angle <= 135) ? a : Float.pi - a
        return float2(-nf.z, a)
    }
    
    public func normalForm(toPoint point:float2) -> float3 {
        let form1 = standardForm
        
        let a1 = form1.x
        let b1 = form1.y
        
        var f = float3()
        f.x = -b1
        f.y = a1
        f.z = a1*point.y - b1*point.x
        
        return f
    }

    public func determinants(line:IMPLineSegment) -> (D:Float,Dx:Float,Dy:Float){
        return determinants(standardForm: line.standardForm)
    }
    
    public func determinants(standardForm form:float3) -> (D:Float,Dx:Float,Dy:Float){
        let form1 = standardForm
        let form2 = form
        
        let a1 = form1.x
        let b1 = form1.y
        let c1 = form1.z
        
        let a2 = form2.x
        let b2 = form2.y
        let c2 = form2.z
        
        let D = float2x2(rows: [
            float2(a1,b1),
            float2(a2,b2)
            ]).determinant
        
        let Dx = float2x2(rows: [
            float2(c1,b1),
            float2(c2,b2)
            ]).determinant
        
        let Dy = float2x2(rows: [
            float2(a1,c1),
            float2(a2,c2)
            ]).determinant
        
        return (D,Dx,Dy)
    }
}


let l1 = IMPLineSegment(p0: float2(0.0, 0.890362), p1: float2(1.0, 0.585374))
let l2 = IMPLineSegment(p0: float2(0.0, 0.93291),  p1: float2(1.0, 0.627922))
let v1 = IMPLineSegment(p0: float2(0.771672, 0.0), p1: float2(0.975498, 1.0))
let v2 = IMPLineSegment(p0: float2(0.193715, 0.0), p1: float2(0.38245, 1.0))


let h1 = l1.houghSpace(size:NSSize(width:800.0, height:654.0))
let h2 = l2.houghSpace(size:NSSize(width:800.0, height:654.0))

let hv1 = v1.houghSpace(size:NSSize(width:800.0, height:654.0))
let hv2 = v2.houghSpace(size:NSSize(width:800.0, height:654.0))

h1.y * 180 / Float.pi
h2.y * 180 / Float.pi

hv1.y * 180 / Float.pi
hv2.y * 180 / Float.pi


