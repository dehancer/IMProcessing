//
//  IMPCubicSpline.swift
//  Pods
//
//  Created by Denis Svinarchuk on 26/06/2017.
//
//

import Foundation
import Surge
import simd

//
// https://en.wikipedia.org/wiki/Spline_interpolation
//

public class IMPCubicSpline:IMPInterpolator {
    
    public var bounds:(left:float2,right:float2) = (float2(0), float2(1)) { didSet{ didUpdate() } }

    public var secondDerivative:Float = 1 { didSet{ didUpdate() } }
    
    public var minimumControls: Int {return 3}
    
    public var controls:[float2] = [float2]() { didSet{ didUpdate() } }
    
    public var resolution:Int
    
    public required init(resolution:Int) {
        self.resolution = resolution
    }
    
    public func value(at x:Float) -> Float {
        guard controls.count > minimumControls else { return x }

        if let y = testBounds(at: x) { return y }

        guard let i = controlIndices(at: x) else { return x }
        
        let h  = controls[i.1].x - controls[i.0].x
        let x0 = x - controls[i.0].x
        let x1 = controls[i.1].x - x
        
        var y = powf(x1,3) * coeffs[i.0] + powf(x0, 3) * coeffs[i.1]
            y = y/6/h
            let z = coeffs[i.0]*x1 + coeffs[i.1]*x0
            y = y - z*h/6
            y = y + (controls[i.0].y*x1 + controls[i.1].y*x0)/h
        
        return y
    }
    
    private func didUpdate() {
        guard controls.count > minimumControls else { return }
        coeffs = getCoeffs()
    }
    
    private var coeffs = [Float]()
    
    private func getCoeffs() -> [Float] {
        
        let n = controls.count
        let A = Matrix<Float>(rows: n, columns: n, repeatedValue: 0)
        var B = Matrix<Float>(rows: n, columns: 1, repeatedValue: 0)
        
        A[0,0]     = 2
        A[n-1,n-1] = 2
        A[0,1]     = 1
        A[n-1,n-2] = 1
        
        B[0,0]     = 0 // the first derivative == 1
        
        var h1:Float = 0
        
        for i in 1..<n-1 {
            let h0 = controls[i].x   - controls[i-1].x
            h1     = controls[i+1].x - controls[i].x
            let h2 = controls[i+1].x - controls[i-1].x
            
            if h2 == 0 {
                A[i,i-1] = 0
                A[i,i+1] = 0
                B[i,0]   = 0
            }
            else {
                A[i,i-1] = h0/h2
                A[i,i+1] = h1/h2
                let y   = controls[i].y
                let fx0 = (h0 == 0 ? 0 : (y-controls[i-1].y)/h0)
                let fx1 = (h1 == 0 ? 0 : (controls[i+1].y-y)/h1)
                B[i,0]  = 6 * (fx1 - fx0) / h2
            }
            
            A[i,i] = 2
            
        }
        
        B[n-1,0] = 6 * (secondDerivative-(controls[n-1].y-controls[n-2].y)/h1)/h1
        
        do {
            _ = try Surge.solve(a: A, b: &B)
        }
        catch let error {
            NSLog("IMPCubicSpline: \(error)")
        }
        
        var b = B[column:0]
        b.append(0)

        return b
    }
}
