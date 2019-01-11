//
//  TPSpline.swift
//  Pods
//
//  Created by Denis Svinarchuk on 02/05/2017.
//
//

import Foundation
import simd
import Accelerate
import Surge
typealias LAInt = __CLPK_integer // = Int32

//
// Sources : https://www.ludd.ltu.se/~torger/dcamprof.html
//

// MARK: - 3D Thin Plate surface spline
public extension Collection where Iterator.Element == [Float] {
    
    public func tpSpline(controls controlPoints:[float3], scale:Float=0, regularization:Float = 0)  -> [Float]{
        if self.count != 2 {
            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
        }
        let tps = IMPTPSpline(controls: controlPoints, regularization: regularization)
        return self.tpSpline(tps:tps, scale:scale, regularization:regularization)
    }
    
    public func tpSpline(tps:IMPTPSpline, scale:Float=0, regularization:Float = 0)  -> [Float]{
        
        if self.count != 2 {
            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
        }
        
        var curve   = [Float]()
        let xPoints = self[0 as! Self.Index]
        let yPoints = self[count - 1 as! Self.Index]
        
        for y in yPoints {
            for x in xPoints {
                curve.append(tps[float2(x,y)])
            }
        }
        
        if scale>0 {
            var max:Float = 0
            vDSP_maxv(curve, 1, &max, vDSP_Length(curve.count))
            max = scale/max
            vDSP_vsmul(curve, 1, &max, &curve, 1, vDSP_Length(curve.count))
        }
        
        return curve
    }
}

public protocol IMP3DInterpolator{
    
    var controls:[float3] {get}
    var interval:Float {get}
    
    init(controls points:[float3])
    func value(at t:float2) -> Float
}


public extension IMP3DInterpolator {
    
    public subscript(_ t: float2) -> Float {
        return value(at: t)
    }
    
    public func bounds(at t:Float) -> Int {
        return bounds(at: Int(t/interval))
    }
    
    public func bounds(at t:Int) -> Int {
        return t <= 0 ? 0 :  t >= (controls.count-1) ? controls.count - 1 : t
    }
}

public class IMPTPSpline:IMP3DInterpolator{
  
    public var weights:[Float] {
        return V[column:0]
    }

    public var alpha:Float {
        return _alpha
    }
    
    public var regularization:Float = 0 {
        didSet{
            prepare()
        }
    }
    public var controls: [float3] {
        didSet{
            prepare()
        }
    }
    
    public init(controls points: [float3], regularization lambda:Float) {
        controls = points
        regularization = lambda
        prepare()
    }
    
    public required init(controls points: [float3]) {
        controls = points
        prepare()
    }
    
    private func prepare() {
        K = makeKMatrix()
        L = makeLMatrix()
        V = makeVMatrix()
        _alpha = prepareK()
        prepareP()
        prepareO()
        prepareV()
        solve()
    }
    
    public var interval: Float {
        return 1/Float(controls.count)
    }
    
    public func value(at t: float2) -> Float {
        let p = controls.count
        var h = V[p+0, 0] + V[p+1, 0]*t.x + V[p+2, 0]*t.y
        var pt_i = float3()
        let pt_cur = float3(t.x,t.y,0)
        for i in 0..<p {
            pt_i = controls[i]
            pt_i[2] = 0
            h += V[i,0] * IMPTPSpline.baseFunction(difflen(pt_i, pt_cur))
        }
        
        return h
    }
    
    private var _alpha:Float = 0
    
    private func difflen(_ i:float3, _ j:float3) -> Float {
        return distance(i, j)
    }
    
    private func prepareK() -> Float {
        let p = controls.count
        
        // Fill K (p x p, upper left of L) and calculate
        // mean edge length from control points
        //
        // K is symmetrical so we really have to
        // calculate only about half of the coefficients.
        var a:Float = 0
        
        for i in 0..<p {
            for j in i+1..<p {
                var pt_i = controls[i]
                var pt_j = controls[j]
                pt_i[2] = 0
                pt_j[2] = 0
                let elen = difflen(pt_i, pt_j)
                let u = IMPTPSpline.baseFunction(elen)
                L[i,j] = u
                L[j,i] = u
                K[i,j] = u
                K[j,i] = u
                
                a += elen * 2 // same for upper & lower tri
            }
        }
        a /= Float(p*p)
        
        return a
    }
    
    private func prepareP()  {
        let p = controls.count
        
        // Fill the rest of L
        for i in 0..<p {
            // diagonal: reqularization parameters (lambda * a^2)
            let r = regularization * (alpha*alpha)
            L[i,i] = r
            K[i,i] = r
            
            // P (p x 3, upper right)
            
            L[i, p+0] = 1
            L[i, p+1] = controls[i][0]
            L[i, p+2] = controls[i][1]
            
            // P transposed (3 x p, bottom left)
            L[p+0, i] = 1
            L[p+1, i] = controls[i][0]
            L[p+2, i] = controls[i][1]
        }
    }
    
    private func prepareO() {
        let p = controls.count
        
        // O (3 x 3, lower right)
        for i in p..<p+3 {
            for j in p..<p+3 {
                L[i,j] = 0
            }
        }
    }
    
    private func prepareV() {
        let p = controls.count
        // Fill the right hand vector V
        for i in 0..<p {
            V[i,0] = controls[i][2]
        }
    }
    
    private func solve()  {
        do {
            _ = try Surge.solve(a: L, b: &V)
        } catch let error {
            NSLog("IMPTSpline error: \(error)")
        }
    }

    func makeLMatrix() -> Matrix<Float> {
        return Matrix<Float>(rows:self.controls.count+3, columns:self.controls.count+3, repeatedValue:0)
    }

    func makeKMatrix() -> Matrix<Float> {
        return Matrix<Float>(rows:self.controls.count, columns:self.controls.count, repeatedValue:0)
    }

    func makeVMatrix() -> Matrix<Float> {
        return Matrix<Float>(rows:self.controls.count+3, columns:1, repeatedValue:0)
    }

    lazy var L:Matrix<Float> = self.makeLMatrix()
    lazy var K:Matrix<Float> = self.makeKMatrix()
    lazy var V:Matrix<Float> = self.makeVMatrix()
    
    public static func baseFunction(_ r:Float) -> Float
    {
        if ( r == 0.0 ) { return 0.0 }
        else {return r*r * log(r) }
    }
    
    public var bendingEnergy: Float {
        
        let p = controls.count
        let w = Matrix<Float>(rows:p,columns:1,repeatedValue:0)
        
        for i in 0..<p {
            w[i,0] = V[i,0]
        }
        let w_trans = transpose(w)

        let prod = w_trans * K

        let be = prod * w
        
        return be[0,0]
    }
}
