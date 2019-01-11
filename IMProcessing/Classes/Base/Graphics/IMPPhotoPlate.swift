//
//  IMPPhotoPlate.swift
//  Pods
//
//  Created by denis svinarchuk on 19.02.17.
//
//

import Metal

/// Photo plate model
public class IMPPhotoPlate: IMPVertices{
    
    /// Plate vertices
    public let vertices:[IMPVertex]
    
    /// Aspect ratio of the plate sides
    public let aspect:Float
    
    /// Processing region
    public let region:IMPRegion
    
    public func quad(model:IMPTransfromModel) -> IMPQuad {
        let v = xyProjection(model: model)
        var q = IMPQuad(left_bottom: v[1], left_top: v[0], right_bottom: v[2], right_top: v[5])
        q.aspect = aspect
        return q
    }
    
    public func quad() -> IMPQuad {
        var q = IMPQuad(left_bottom: vertices[1].position.xy,
                        left_top: vertices[0].position.xy,
                        right_bottom: vertices[2].position.xy,
                        right_top: vertices[5].position.xy)
        q.aspect = aspect
        return q
    }
    
    public init(aspect a:Float = 1, region r:IMPRegion = IMPRegion()){
        aspect = a
        region = r
        
        // Front
        let A = IMPVertex(x: -1*aspect, y:   1, z:  0, tx: region.left,    ty: region.top)      // left-top
        let B = IMPVertex(x: -1*aspect, y:  -1, z:  0, tx: region.left,    ty: 1-region.bottom) // left-bottom
        let C = IMPVertex(x:  1*aspect, y:  -1, z:  0, tx: 1-region.right, ty: 1-region.bottom) // right-bottom
        let D = IMPVertex(x:  1*aspect, y:   1, z:  0, tx: 1-region.right, ty: region.top)      // right-top
        
        vertices = [
            A,B,C, A,C,D,   // The main front plate. Here we put image.
        ]
    }
}
