//
//  IMPCurveFunction.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 16.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

public var kIMPCurveCollectionResolution = 256

public enum IMPCurveCollection: String {
    
    case cubic       = "Cubic"
    case catmullRom  = "CatmullRom"
    case bezier      = "Bezier"
    case bspline     = "BSpline"
    case polyline    = "Polyline"
    
    public var curve:IMPCurve {
        switch self {
        case .catmullRom:
            return  IMPCurve(interpolator: IMPCatmulRomSpline(resolution: kIMPCurveCollectionResolution), type:.interpolated)
            
        case .bezier:
            return IMPCurve(interpolator: IMPBezierSpline(resolution: kIMPCurveCollectionResolution),
                            type:     .smooth,
                            edges:    ([float2(0)],[float2(1)]),
                            initials: ([float2(0)],[float2(1)]),
                            maxControlPoints: 2)
            
        case .bspline:
            return  IMPCurve(interpolator: IMPBSpline(resolution: kIMPCurveCollectionResolution),
                             type:.smooth,
                             edges:    ([float2(0)],[float2(1)]))
            
        case .polyline:
            return IMPCurve(interpolator: IMPLinearInterpolator(resolution: kIMPCurveCollectionResolution), type: .interpolated)
            
        default:
            return IMPCurve(interpolator: IMPCubicSpline(resolution: kIMPCurveCollectionResolution),
                            type: .interpolated,
                            edges: ([float2(-10000)],[float2(10000)]))
        }
    }
}

