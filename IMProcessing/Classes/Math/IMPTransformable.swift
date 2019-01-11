//
//  IMPDeformable.swift
//  IMProcessing
//
//  Created by denn on 11.08.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Foundation
import simd

public protocol IMPTransformPoint:Collection{
    associatedtype Vector
    init()
    init(_ x:Float)
    init(_ x:Vector)
    func distance(to y: Vector) -> Float
    func value(at:Int) -> Float
}

extension float2:IMPTransformPoint {
    
    public init(_ x: Vector) {
        self = x

    }
    
    public typealias Vector = float2
    
    public func distance(to y: Vector) -> Float {
        return simd.distance(self,y)
    }
    
    public func value(at index: Int) -> Float {
        return self[index]
    }
    
}

extension float3:IMPTransformPoint {
    
    public init(_ x: Vector) {
        self = x
    }
    
    public typealias Vector = float3
    public func distance(to y: Vector) -> Float {
        return simd.distance(self,y)
    }
    public func value(at index: Int) -> Float {
        return self[index]
    }
}

public struct IMPControlPoints<T:IMPTransformPoint> {
    public let p:[T]
    public let q:[T]
    
    public init(p:[T], q:[T]){
        self.p = p
        self.q = q
    }
    
    public init() {
        self.p = [T()]
        self.q = [T()]
    }     
}

public protocol IMPTransformable {
    associatedtype Vector:IMPTransformPoint
    var points:[Vector] {set get}
    func process(controls:IMPControlPoints<Vector>, complete:((_ points:[Vector])->Void)?) throws
}

open class IMPTransformation<T:IMPTransformPoint>:IMPTransformable{
    open var points: [T] = []
    open func process<T>(controls: IMPControlPoints<T>, complete: (([T]) -> Void)?) throws {}
    public typealias Vector = T
    public init() {}
}
