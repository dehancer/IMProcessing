//
//  TpsSolver.swift
//  IMProcessing
//
//  Created by denn on 10.08.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Foundation

public class IMPTpsTransform<T:IMPTransformPoint>: IMPTransformation<T> {
    
    //public typealias Vector = float3
    
    //public var points: [Vector] = []
    
    public var lambda: Float = 1
    
    public init(points:[Vector]?=nil,
                controls:IMPControlPoints<Vector>?=nil,
                lambda:Float = 1,
                complete:((_ points:[Vector])->Void)? = nil) {
        
        super.init()
        
        self.lambda = lambda
        
        if let s = points {
            self.points = s
        }
        if let controls = controls,
            controls.p.count == controls.q.count && controls.p.count > 0 && self.points.count > 0 {
            try? process(controls: controls, complete: complete)
        }
    }
    
    public override func process<T>(controls: IMPControlPoints<T>, complete: (([T]) -> Void)?) throws where T : IMPTransformPoint {
        if Vector() is float2 {
            process_float2(controls: controls as! IMPControlPoints<float2>, complete: complete as? (([float2]) -> Void))
        }
        else if Vector() is float3  {
            process_float3(controls: controls as! IMPControlPoints<float3>, complete: complete as? (([float3]) -> Void))
        }
    }
}

extension IMPTpsTransform {
    
    public func process_float2(controls: IMPControlPoints<float2>, complete: (([float2]) -> Void)?) {
        
        var cp = controls.p
        var cq = controls.q
        let count = Int32(cp.count)
        
        let tps = IMPTpsSolver2D(&cp, destination: &cq, count: count, lambda:lambda)
        
        var result = [Vector](repeating: Vector(), count: points.count)
        
        for (i,p) in points.enumerated() {
            result[i] = tps.value(p as! float2) as! IMPTpsTransform<T>.Vector
        }
        
        complete?(result as! [float2])
    }
}


extension IMPTpsTransform {
    
    public func process_float3(controls: IMPControlPoints<float3>, complete: (([float3]) -> Void)?) {
        
        var cp = controls.p
        var cq = controls.q
        let count = Int32(cp.count)
        
        let tps = IMPTpsSolver3D(&cp, destination: &cq, count: count, lambda:lambda)

        var result = [Vector](repeating: Vector(), count: points.count)
        
        for (i,p) in points.enumerated() {
            result[i] = tps.value(p as! float3) as! IMPTpsTransform<T>.Vector
        }
        
        complete?(result as! [float3])
    }
}
