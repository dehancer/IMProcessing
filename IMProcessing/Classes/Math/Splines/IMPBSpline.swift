//
//  IMPCubicBetaSpline.swift
//  Pods
//
//  Created by denis svinarchuk on 25.06.17.
//
//


import Foundation
import simd

public class IMPBSpline:IMPMatrixBasedSpline{
    
    public override var matrix:float4x4 { return Mb }
    
    private lazy var Mb:float4x4 = self.baseMatrix()
    
    private func baseMatrix() -> float4x4 {
        return 1/6 * float4x4(rows:[
            float4(  1, 4, 1, 0),
            float4( -3, 0, 3, 0),
            float4(  3,-6, 3, 0),
            float4( -1, 3,-3, 1)
            ]);
    }
    
}
