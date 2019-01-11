//
//  IMPCatmulRomSpline.swift
//  Pods
//
//  Created by denis svinarchuk on 25.06.17.
//
//

import Foundation
import Surge
import simd

public class IMPCatmulRomSpline:IMPMatrixBasedSpline{
    
    //
    // CatmulRom tension is 1/2 by default
    //
    public var tension:Float = 0.5 { didSet{ Mb = self.baseMatrix(); didControlsUpdate() } }
    
    public override var matrix:float4x4 { return Mb }
    
    private lazy var Mb:float4x4 = self.baseMatrix()
    
    //
    // Cardinal base
    //
    private func baseMatrix() -> float4x4 {
        return tension * float4x4(rows:[
            float4( 0,  1/tension,    0,            0),
            float4(-1,  0,            1,            0),
            float4( 2, -3/tension+1,  3/tension-2, -1),
            float4(-1,  2/tension-1, -2/tension+1,  1)
            ]);
    }
    
}
