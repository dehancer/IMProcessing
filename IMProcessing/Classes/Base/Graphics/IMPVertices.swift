//
//  IMPVertices.swift
//  Pods
//
//  Created by denis svinarchuk on 19.02.17.
//
//

import Metal

// MARK: - Vertex structure
public extension IMPVertex{
    public init(x:Float, y:Float, z:Float, tx:Float, ty:Float){
        self.init()
        self.position = float3(x,y,z)
        self.texcoord = float3(tx,ty,1)
    }
    /// Get vertex raw buffer
    public var raw:[Float] {
        return [position.x,position.y,position.z,texcoord.x,texcoord.y,1]
    }
}

///  @brief Vertices protocol
public protocol IMPVertices{
    var vertices:[IMPVertex] {get}
}

// MARK: - Vertices basic read properties
public extension IMPVertices{
    
    /// Raw buffer
    public var raw:[Float]{
        var vertexData = [Float]()
        for vertex in vertices{
            vertexData += vertex.raw
        }
        return vertexData
    }
    
    /// Vertices count
    public var count:Int {
        return vertices.count
    }
    
    /// Vertices buffer langth
    public var length:Int{
        return vertices.count * MemoryLayout.size(ofValue: vertices[0])
    }
    
    ///  XY plane projection
    ///
    ///  - parameter model: 3D matrix transformation model
    ///
    ///  - returns: x,y coordinates
    public func xyProjection(model:IMPTransfromModel) -> [float2] {
        var points = [float2]()
        for v in vertices {
            
            let xyzw = float4(v.position.x,v.position.y,v.position.z,1)
            let result = model.matrix * xyzw
            let t = (1+result.z)/2
            let xy = float2(result.x/t, result.y/t)
            
            points.append(xy)
            
        }
        return points
    }
    
    
    ///  Scale factor to find largest inscribed quadrangle
    ///
    ///  - parameter model: transformation matrix model
    ///
    ///  - returns: scale factor
    public func scaleFactorFor(model:IMPTransfromModel) -> Float {
        let points = xyProjection(model: model)
        
        var left:Float   = 0
        var right:Float  = 0
        var bottom:Float = 0
        var top:Float    = 0
        
        for p in points {
            
            if p.x<0 {
                if abs(p.x) > left {
                    left = abs(p.x)
                }
            }
            
            if p.x>=0 {
                if abs(p.x) > right {
                    right = abs(p.x)
                }
            }
            
            if p.y<0 {
                if abs(p.y) > bottom {
                    bottom = abs(p.y)
                }
            }
            
            if p.y>=0 {
                if abs(p.y) > top {
                    top = abs(p.y)
                }
            }
        }
        
        let W:Float = 2
        let H:Float = 2
        let w = left + right
        let h = top + bottom
        
        let scale = min(W / w, H / h)
        
        return scale > 1 ? 2-scale : scale
    }
}
