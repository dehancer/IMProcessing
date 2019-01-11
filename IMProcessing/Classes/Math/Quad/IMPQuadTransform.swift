//
//  IMPQuadTransform.swift
//  IMProcessing
//
//  Created by denn on 19.09.2018.
//

import Foundation
import Surge

public extension float2x2 {
    
    public static func makeRotationMatrix(angle: Float) -> float2x2 {
        let rows = [
            float2( cos(angle), sin(angle)),
            float2(-sin(angle), cos(angle)),
            ]
        return float2x2(rows: rows)
    }
    
    public func rotate(_ point: float2) -> float2 {
        let uv = (point - float2(0.5)) * self
        return uv + float2(0.5)
    }
}

public class IMPQuadTransform<T:IMPTransformPoint>: IMPTransformation<T> {
    
    public var angle:Float = 0
    
    /// Quad transform finds target points of quad transformation
    ///
    /// - Parameters:
    ///   - points: points of inpunt fields
    ///   - controls: control points: p and q, where p - the source, q - target locations
    ///               controls must be sorted for left-top system, controls count must be equal 4 points
    ///   - complete: calls when result is computed for new field
    public init(points:[Vector]?,
                controls:IMPControlPoints<Vector>?=nil,
                angle:Float = 0,
                complete:((_ points:[Vector])->Void)? = nil) throws {
        
        super.init()
        
        self.angle = angle
        
        if let s = points { self.points = s }
        
        if let controls = controls,
            controls.p.count == controls.q.count && controls.p.count > 0 && self.points.count > 0 {
            try process(controls: controls, complete: complete)
        }
    }
    
    public convenience init(points:[Vector]?=nil) {
        try! self.init(points: points, controls: nil, angle: 0, complete: nil)
    }
    
    /// Process "Quad" transformation for the points of fields
    ///
    /// - Parameters:
    ///   - controls: control points
    ///   - complete: calls when result is computed for new field
    /// - Throws: ...
    public override func process<T>(controls: IMPControlPoints<T>,
                                    complete: (([T]) -> Void)?) throws where T : IMPTransformPoint {
        if Vector() is float2 {
            try process_float2(controls: controls as! IMPControlPoints<float2>, complete: complete as? (([float2]) -> Void))
        }
    }
}

extension IMPQuadTransform {
    
    public func process_float2(controls: IMPControlPoints<float2>, complete: (([float2]) -> Void)?)  throws {
        
        let rotation = float2x2.makeRotationMatrix(angle: angle)
        
        let cp = controls.p
        let cq = controls.q
        
        var result = [float2](repeating: float2(0), count: points.count)
        
        guard let quad = try IMPQuadSolver(source: cp,
                                           destination: cq) else { return }
        
        
        for (i,p) in points.enumerated() {
            result[i] = rotation.rotate(quad.value(p as! float2))
        }
        
        complete?(result)
    }
}

public class IMPQuadSolver  {
    
    private class Quad {
        public var leftTop     = float2(0)
        public var leftBottom  = float2(0,1)
        public var rightTop    = float2(1,0)
        public var rightBottom = float2(1)
        
        public var points:[float2] {
            return [leftTop,rightTop,rightBottom,leftBottom]
        }
        
        public init(_ points:[float2]) {
            guard points.count >= 4 else { return }
            leftTop     = points[0]
            leftBottom  = points[3]
            rightTop    = points[1]
            rightBottom = points[2]
        }
    }
    
    public init?(source: [float2], destination: [float2]) throws {
        if source.count != destination.count && source.count != 4 {
            fatalError("IMPQuadTransform must contain 4 control points are sorted for left-top quad...")
        }
        self.source = Quad(source)
        self.destination =  Quad(destination)
        
        try matrix = transform()
    }
    
    public func value (_ point:float2) -> float2 {
        return matrix.transform(point)
    }
    
    private let source:Quad
    private let destination:Quad
    public var matrix:float3x3 = float3x3(diagonal: float3(1))
    
    private func transform() throws -> float3x3 {
        let A = Matrix<Float>(rows:8,columns:8, repeatedValue:0)
        var B = Matrix<Float>(rows:8,columns:1, repeatedValue:0)
        for i in 0..<4 {
            let k = i*2
            A[row:k]   = [source.points[i].x,
                          source.points[i].y,
                          1, 0, 0, 0,
                          -source.points[i].x * destination.points[i].x,
                          -source.points[i].y * destination.points[i].x]
            
            A[row:k+1] = [0, 0, 0,
                          source.points[i].x,
                          source.points[i].y, 1,
                          -source.points[i].x * destination.points[i].y,
                          -source.points[i].y * destination.points[i].y]
        }
        for i in 0..<4 {
            let k = i*2
            B[k,0]   = destination.points[i].x
            B[k+1,0] = destination.points[i].y
        }
        
        try solve(a: A, b: &B)
        
        let h = B[column:0]
        
        return float3x3(rows: [
            float3(h[0],h[1],h[2]),
            float3(h[3],h[4],h[5]),
            float3(h[6],h[7],1)
            ])
    }
}

extension float3x3 {
    func transform(_ point:float2) -> float2 {
        let np = self * float3(point.x,point.y,1)
        return np.xy/float2(np.z)
    }
    
    func transform(_ point:float3) -> float3 {
        return self * point
    }
}
