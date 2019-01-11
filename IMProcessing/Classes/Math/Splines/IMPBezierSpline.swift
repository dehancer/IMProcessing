//
//  IMPBezierSpline.swift
//  Pods
//
//  Created by denis svinarchuk on 25.06.17.
//
//

import Foundation
import Surge
import simd

public class IMPBezierSpline:IMPMatrixBasedSpline{
    
    public override var matrix:float4x4 { return Mb }
    
    private lazy var Mb:float4x4 = self.baseMatrix()
    
    private func baseMatrix() -> float4x4 {
        return float4x4(rows:[
            float4( 1,  0,  0, 0),
            float4(-3,  3,  0, 0),
            float4( 3, -6,  3, 0),
            float4(-1,  3, -3, 1)
            ]);
    }
}

