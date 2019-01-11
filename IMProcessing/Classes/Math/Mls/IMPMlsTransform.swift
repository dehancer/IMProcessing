//
//  IMPMlsProcessing.swift
//  TPSExperiment
//
//  Created by denn on 04.09.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Foundation

public class IMPMlsTransform<T:IMPTransformPoint>: IMPTransformation<T> {
    
    public var kind: IMPMlsSolverKind = .affine
    public var alpha: Float = 1

    public init(points:[Vector]?=nil,
                controls:IMPControlPoints<Vector>?=nil,
                kind:IMPMlsSolverKind = .affine,
                alpha:Float = 1,
                complete:((_ points:[Vector])->Void)? = nil) {
        
        super.init()
        
        self.kind = kind
        self.alpha = alpha

        if let s = points { self.points = s }
        
        if let controls = controls,
            controls.p.count == controls.q.count && controls.p.count > 0 && self.points.count > 0 {
            try? process(controls: controls, complete: complete)
        }
    }
    
    public override func process<T>(controls: IMPControlPoints<T>, complete: (([T]) -> Void)?) throws where T : IMPTransformPoint {
        if Vector() is float2 {
            process_float2(controls: controls as! IMPControlPoints<float2>, complete: complete as? (([float2]) -> Void))
        }
    }
}

extension IMPMlsTransform {
    
    public func process_float2(controls: IMPControlPoints<float2>, complete: (([float2]) -> Void)?) {
        var cp = controls.p
        var cq = controls.q
        let count = Int32(cp.count)
        
        var result = [float2](repeating: float2(0), count: points.count)
        
        for (i,p) in points.enumerated() {
            guard let mls = IMPMlsSolver(p as! float2,
                                         source: &cp,
                                         destination: &cq,
                                         count: count,
                                         kind: kind,
                                         alpha: alpha) else {continue}
            result[i] = mls.value(p as! float2)
        }
        complete?(result)
    }
}
