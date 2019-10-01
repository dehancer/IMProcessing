//
//  IMPSimd.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import simd

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

// MARK: - Vector extensions

public extension Float {
    public func lerp(final:Float, t:Float) -> Float {
        return (1-t)*self + t*final
    }
}

// float2

public extension float2 {

    public static func == (left:float2,right:float2) -> Bool {
        return (left.x == right.x) && (left.y == right.y)
    }
    
    public static func != (left:float2,right:float2) -> Bool {
        return (left.x != right.x) && (left.y != right.y)
    }

    public func lerp(final:float2, t:Float) -> float2 {
        return (1-t)*self + t*final
    }
}

// float3

public extension float3 {
    
//    public static func == (left:float3,right:float3) -> Bool {
//        return (left.x == right.x) && (left.y == right.y) && (left.z == right.z)
//    }
//
//    public static func != (left:float3,right:float3) -> Bool {
//        return !(left == right)
//    }
    
    public func lerp(final:float3, t:Float) -> float3 {
        return (1-t)*self + t*final
    }
    
    var xy:float2 { get{ return float2(x,y) }   set{self.x=newValue.x; self.y=newValue.y}}
    var xz:float2 { get{ return float2(x,z) }   set{self.x=newValue.x; self.z=newValue.y}}
    var yz:float2 { get{ return float2(y,z) }   set{self.y=newValue.x; self.z=newValue.y}}
    var xxx:float3 { get{ return float3(x,x,x)}}
    var yyy:float3 { get{ return float3(y,y,y)}}
    var zzz:float3 { get{ return float3(z,z,z)}}
}

// float4

public extension float4 {

    static func == (left:float4,right:float4) -> Bool {
        return (left.x == right.x) && (left.y == right.y) && (left.z == right.z) && (left.w == right.w)
    }
    
    static func != (left:float4,right:float4) -> Bool {
        return !(left == right)
    }

    func lerp(final:float4, t:Float) -> float4 {
        return (1-t)*self + t*final
    }

    var xy:float2 { get{ return float2(x,y) } set{self.x=newValue.x; self.y=newValue.y}}
    var zw:float2 { get{ return float2(z,w) } set{self.z=newValue.x; self.w=newValue.y}}
    var wz:float2 { get{ return float2(w,z) } set{self.w=newValue.x; self.z=newValue.y}}
    
    var xxx:float3 { get{ return float3(x,x,x) } }
    var yyy:float3 { get{ return float3(y,y,y) } }
    var zzz:float3 { get{ return float3(z,z,z) } }
    var www:float3 { get{ return float3(w,w,w) } }
    
    var xyw:float3 { get{ return float3(x,y,w) } set{self.x=newValue.x; self.y=newValue.y; self.w=newValue.z}}
    var xwy:float3 { get{ return float3(x,w,y) } set{self.x=newValue.x; self.w=newValue.y; self.y=newValue.z}}
    var wxy:float3 { get{ return float3(w,x,y) } set{self.w=newValue.x; self.x=newValue.y; self.y=newValue.z}}
    var yzx:float3 { get{ return float3(y,z,x) } set{self.y=newValue.x; self.z=newValue.y; self.x=newValue.z}}
    var xyz:float3 { get{ return float3(x,y,z) } set{self.x=newValue.x; self.y=newValue.y; self.z=newValue.z}}
}


// MARK: - Matrix constructors
public extension float3x3 {
    init(rows: [[Float]]){
        self.init(matrix_from_rows(vector_float3(rows[0]), vector_float3(rows[1]), vector_float3(rows[2])))
    }
    
    init(_ columns: [[Float]]){
        self.init(float3x3(vector_float3(columns[0]), vector_float3(columns[1]), vector_float3(columns[2])))
    }
}

public extension float4x4 {
    init(rows: [[Float]]){
        self.init(matrix_from_rows(float4(rows[0]), float4(rows[1]), float4(rows[2]),float4(rows[3])))
    }
}

public extension matrix_float3x3{
    
    public init(rows: (float3,float3,float3)){
        self = matrix_from_rows(rows.0, rows.1, rows.2)
    }
    
//    public init(rows: [float3]){
//        self = matrix_from_rows(rows[0], rows[1], rows[2])
//    }
    
    public init(columns: [float3]){
        self = float3x3(columns[0], columns[1], columns[2])
    }
    
//    public init(rows: [[Float]]){
//        self = matrix_from_rows(float3(rows[0]), float3(rows[1]), float3(rows[2]))
//    }
    
    public init(columns: [[Float]]){
        self = float3x3(float3(columns[0]), float3(columns[1]), float3(columns[2]))
    }
    
//    public func toFloat3x3() -> float3x3 {
//        return self
//    }
}


public extension matrix_float4x4{
    
    public init(rows: (float4,float4,float4,float4)){
        self = matrix_from_rows(rows.0, rows.1, rows.2, rows.3)
    }
    
    public init(rows: [float4]){
        self = matrix_from_rows(rows[0], rows[1], rows[2], rows[3])
    }
    
    public init(columns: [float4]){
        self = float4x4(columns[0], columns[1], columns[2], columns[3])
    }
    
//    public init(rows: [[Float]]){
//        self = matrix_from_rows(float4(rows[0]), float4(rows[1]), float4(rows[2]), float4(rows[3]))
//    }
    
    public init(columns: [[Float]]){
        self = simd_float4x4(float4(columns[0]), float4(columns[1]), float4(columns[2]), float4(columns[3]))
    }
    
//    public func toFloat4x4() -> float4x4 {
//        return float4x4(self)
//    }
}

// MARK: - Basic matrix transformations
public extension matrix_float4x4 {
    
    public mutating func translate(position p:float3){
        let m0 = self.columns.0
        let m1 = self.columns.1
        let m2 = self.columns.2
        let m3 = self.columns.3
        let m = matrix_float4x4(columns: (
            m0,
            m1,
            m2,
            float4(
                m0.x * p.x + m0.y * p.y + m0.z * p.z + m0.w,
                m1.x * p.x + m1.y * p.y + m1.z * p.z + m1.w,
                m2.x * p.x + m2.y * p.y + m2.z * p.z + m2.w,
                m3.x * p.x + m3.y * p.y + m3.z * p.z + m3.w)
            )
        )
        
        self = matrix_multiply(m,self)
    }
    
    public mutating func scale(factor f:float3)  {
        let m0 = self.columns.0
        let m1 = self.columns.1
        let m2 = self.columns.2
        let m3 = self.columns.3
        
        let rows = [
            [m0.x * f.x, m1.x * f.x, m2.x * f.x, m3.x ],
            [m0.y * f.y, m1.y * f.y, m2.y * f.y, m3.y ],
            [m0.z * f.z, m1.z * f.z, m2.z * f.z, m3.z ],
            [m0.w,     m1.w,     m2.w,     m3.w ],
            ]
        
        self = matrix_float4x4(rows: rows)
    }
    
    public mutating func rotate(radians:Float, point:float3) {
        
        let v =  normalize(point)
        let _cos = cosf(radians)
        let cosp = 1.0 - _cos
        let _sin = sinf(radians)
        
        let m00 = _cos + cosp * v[0] * v[0]
        let m01 = cosp * v[0] * v[1] + v[2] * _sin
        let m02 = cosp * v[0] * v[2] - v[1] * _sin
        let mm0 = [m00, m01, m02, 0.0]
        
        let m10 = cosp * v[0] * v[1] - v[2] * _sin
        let m11 = _cos  + cosp * v[1] * v[1]
        let m12 = cosp * v[1] * v[2] + v[0] * _sin
        let mm1 =  [m10, m11, m12, 0.0]
        
        let m20 = cosp * v[0] * v[2] + v[1] * _sin
        let m21 = cosp * v[1] * v[2] - v[0] * _sin
        let m22 = _cos  + cosp * v[2] * v[2]
        let mm2 = [m20, m21, m22, 0.0]
        let mm3:[Float] = [0.0, 0.0, 0.0, 1.0]
        
        let m = [ mm0, mm1, mm2, mm3 ]
        
        self = matrix_multiply(matrix_float4x4(rows: m),self)
    }
}

// MARK: - Basic algebra
public extension float2x2 {
    var determinant:Float {
        get {
            let t = self.columns //cmatrix.columns
            return t.0.x*t.1.y - t.0.y*t.1.x
        }
    }
}

public extension float3x3 {
    var determinant:Float {
        get {
            let t  = self.transpose
            let a1 = t.columns.0
            let a2 = t.columns.1
            let a3 = t.columns.2
            return a1.x*a2.y*a3.z - a1.x*a2.z*a3.y - a1.y*a2.x*a3.z + a1.y*a2.z*a3.x + a1.z*a2.x*a3.y - a1.z*a2.y*a3.x
        }
    }
}
