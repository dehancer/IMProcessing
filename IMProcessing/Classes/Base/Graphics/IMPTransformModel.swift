//
//  IMPTransformModel.swift
//  Pods
//
//  Created by denis svinarchuk on 19.02.17.
//
//

import Metal
import simd

public extension IMPTransfromModel{
    public func transform(point:NSPoint) -> NSPoint {
        let p = transform(point: float2(point.x.float,point.y.float))
        return NSPoint(x:p.x.cgfloat,y:p.y.cgfloat)
    }
}

public struct IMPProjectionModel{
    
    public static var identity:IMPProjectionModel { return IMPProjectionModel() }
    
    var projectionMatrix  = matrix_identity_float4x4
    
    public var fovy:Float = Float.pi/2
    public var aspect:Float = 1
    public var near:Float = 0
    public var far:Float = 1
    
    public init(){}
    
    public var matrix:float4x4{
        get {
            let cotan = 1.0 / tanf(fovy / 2.0)
            let m =  [
                [cotan / aspect, 0,     0,                              0],
                [0,              cotan, 0,                              0],
                [0,              0,    (far + near) / (near - far),    -1],
                [0,              0,    (2 * far * near) / (near - far), 0]
            ]
            return matrix_float4x4(columns:m)
        }
    }
}

public struct IMPTransfromModel{
    
    public static let flat       = float3(0,0,0)
    public static let left       = float3(0,0,-90.float.radians)
    public static let right      = float3(0,0,90.float.radians)
    public static let degrees180 = float3(0,0,180.float.radians)
    public static let plus270    = float3(0,0,270.float.radians)
    public static let minus270   = float3(0,0,-270.float.radians)
    public static let right45    = float3(0,0,45.float.radians)
    public static let left45     = float3(0,0,-45.float.radians)
    
    public static let identity = IMPTransfromModel()
    
    var rotationMatrix    = matrix_identity_float4x4 
    var translationMatrix = matrix_identity_float4x4
    var scaleMatrix       = matrix_identity_float4x4
    
    public var projection = IMPProjectionModel()
        
    public init(translation:float3 = float3(0),
                angle:float3 = float3(0),
                scale:float3=float3(1),
                projection:IMPProjectionModel = IMPProjectionModel.identity){
        defer{
            self.projection = projection
            self.angle = angle
            self.translation = translation
            self.scale = scale
        }
    }
    
    public static func with(translation:float3 = float3(0),
                            angle:float3 = float3(0),
                            scale:float3=float3(1),
                            projection:IMPProjectionModel = IMPProjectionModel()) -> IMPTransfromModel {
        return IMPTransfromModel(translation: translation, angle: angle, scale: scale, projection: projection)
    }
    
    
    public func lerp(final:IMPTransfromModel, t:Float) -> IMPTransfromModel {
        var f = self
        f.translation = f.translation.lerp(final: final.translation, t: t)
        f.angle = f.angle.lerp(final: final.angle, t: t)
        f.scale = f.scale.lerp(final: final.scale, t: t)
        return f
    }
    
    public static func with(model:IMPTransfromModel,
                            translation:float3?=nil,
                            angle:float3?=nil,
                            scale:float3?=nil,
                            projection:IMPProjectionModel?=nil) -> IMPTransfromModel{
        
        var newModel = IMPTransfromModel()
        
        if let translation = translation {
            newModel.translation = translation
        }
        else {
            newModel.translation = model.translation
        }
        
        if let angle = angle {
            newModel.angle = angle
        }
        else {
            newModel.angle = model.angle
        }
        
        if let scale = scale {
            newModel.scale = scale
        }
        else {
            newModel.scale = model.scale
        }
        
        if let projection = projection {
            newModel.projection = projection
        }
        else{
            newModel.projection = model.projection
        }
        
        return newModel
    }
    
    public var matrix:float4x4 {
        return projection.matrix * (rotationMatrix * translationMatrix * scaleMatrix)
    }
    
    public func transform(vector:float3) -> float3 {
        return (matrix * float4(vector.x,vector.y,vector.z,1)).xyz
    }
    
    public func transform(point:float2) -> float2 {
        return transform(vector: float3(point.x,point.y,0)).xy
    }
    
    public var angle = float3(0) {
        didSet{
            var a = rotationMatrix//.cmatrix
            a.rotate(radians: angle.x, point:float3(1,0,0))
            a.rotate(radians: angle.y, point:float3(0,1,0))
            a.rotate(radians: angle.z, point:float3(0,0,1))
            rotationMatrix = a //float4x4(a)
        }
    }
    
    public var scale = float3(0) {
        didSet{
            var s = scaleMatrix//.cmatrix
            s.scale(factor: scale)
            //scaleMatrix =  s//float4x4(s)
        }
    }
    
    public var translation = float3(0){
        didSet{
            var t = translationMatrix//.cmatrix
            t.translate(position: translation)
            //translationMatrix = float4x4(t)
        }
    }
}

public extension IMPQuad{
    public func transform(model: IMPTransfromModel) -> IMPQuad {
        var quad = IMPQuad()
        
        for i in 0..<4 {
            quad[i] = point_transform(point: self[i], model: model)
        }
        
        return quad
    }
    
    func point_transform(point: float2, model: IMPTransfromModel) -> float2 {
        let xyzw = float4(point.x, point.y,0,1)
        let result = model.matrix * xyzw
        return result.xy
    }
}
