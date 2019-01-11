//
//  IMPColor.swift
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
import Metal

public extension NSColor{
    
    public convenience init(color:float4) {
        self.init(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
    }
    public convenience init(rgba:float4) {
        self.init(color:rgba)
    }
    public convenience init(rgb:float3) {
        self.init(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: CGFloat(1))
    }
    public convenience init(red:Float, green:Float, blue:Float) {
        self.init(rgb:float3(red,green,blue))
    }
    #if os(iOS)
    public var rgb:float3{
        get{
            return rgba.xyz
        }
    }
    
    public var rgba:float4{
        get{
            var red:CGFloat   = 0.0
            var green:CGFloat = 0.0
            var blue:CGFloat  = 0.0
            var _alpha:CGFloat = 0.0
            getRed(&red, green: &green, blue: &blue, _alpha: &_alpha)
            return float4(red.float,green.float,blue.float,_alpha.float)
        }
    }
    #else
    public var rgb:float3{
    get{
    guard let rgba = self.usingColorSpace(IMProcessing.colorSpace.srgb) else {
    return float3(0)
    }
    return float3(rgba.redComponent.float,rgba.greenComponent.float,rgba.blueComponent.float)
    }
    }
    
    public var rgba:float4{
    get{
    guard let rgba = self.usingColorSpace(IMProcessing.colorSpace.srgb) else {
    return float4(0)
    }
    return float4(rgba.redComponent.float,rgba.greenComponent.float,rgba.blueComponent.float,rgba.alphaComponent.float)
    }
    }
    #endif
    
    public static func * (left:NSColor, right:Float) -> NSColor {
        let rgb = left.rgb
        return NSColor( red: rgb.r*right, green: rgb.g*right, blue: rgb.b*right)
    }
}


//extension float2: Equatable {}
//extension float3: Equatable {}
//extension float4: Equatable {}

// MARK: - Basic color extention

public extension float3 {
    func euclidean_distance(to p_2: float3) -> Float {
        var sum:Float = 0
        for i in 0..<3 {
            sum += pow(self[i]-p_2[i],2.0)
        }
        return sqrt(sum)
    }
    
    func euclidean_distance_lab(to p_2: float3) -> Float {
        let c0 = self.rgb2lab()
        let c1 = p_2.rgb2lab()
        return c0.euclidean_distance(to:c1)
    }
    
}

public extension float3{
    
    public var hue:Float       { set{ x = newValue } get{ return x } }
    public var saturation:Float{ set{ y = newValue } get{ return y } }
    public var value:Float     { set{ z = newValue } get{ return z } }
    
    public var r:Float{ set{ x = newValue } get{ return x } }
    public var g:Float{ set{ y = newValue } get{ return y } }
    public var b:Float{ set{ z = newValue } get{ return z } }
    
    public var bg:float2 { get{ return float2(b,g) } }
    public var gb:float2 { get{ return float2(g,b) } }
    
    public func normalized() -> float3 {
        var vector = self
        var sum = vector.x+vector.y+vector.z
        if (sum==0.0) {
            sum = 1.0
        }
        vector.x/=sum
        vector.y/=sum
        vector.z/=sum
        return vector
    }
    
    public init(color:NSColor){
        #if os(iOS)
            var r = CGFloat(0)
            var g = CGFloat(0)
            var b = CGFloat(0)
            var a = CGFloat(0)
            color.getRed(&r, green:&g, blue:&b, _alpha:&a)
            self.init(Float(r),Float(g),Float(b))
        #else
            self.init(Float(color.redComponent),Float(color.greenComponent),Float(color.blueComponent))
        #endif
    }
    
    public init(colors:[String]){
        self.init(colors[0].floatValue,colors[1].floatValue,colors[2].floatValue)
    }
}

public extension float4{
    
    public var r:Float{ set{ x = newValue } get{ return x } }
    public var g:Float{ set{ y = newValue } get{ return y } }
    public var b:Float{ set{ z = newValue } get{ return z } }
    public var a:Float{ set{ w = newValue } get{ return w } }
    
    public var rgb:float3 {
        set{
            x = rgb.x
            y = rgb.y
            z = rgb.z
        }
        get{
            return float3(x,y,z)
        }
    }
    
    public var bg:float2 { get{ return float2(b,g) } }
    public var gb:float2 { get{ return float2(g,b) } }
    
    public func normalized() -> float4 {
        var vector = self
        var sum = vector.x+vector.y+vector.z+vector.w
        if (sum==0.0) {
            sum = 1.0
        }
        vector.x/=sum
        vector.y/=sum
        vector.z/=sum
        vector.w/=sum
        return vector
    }
    
    public init(_ bg:float2, _ wz:float2){
        self.init(bg.x,bg.y,wz.x,wz.y)
    }
    
    public init(_ r:Float, _ xyz:float3){
        self.init(r,xyz.x,xyz.y,xyz.z)
    }
    
    public init(rgb:float3,a:Float){
        self.init(rgb.x,rgb.y,rgb.z,a)
    }
    
    public init(color:NSColor){
        #if os(iOS)
            var r = CGFloat(0)
            var g = CGFloat(0)
            var b = CGFloat(0)
            var a = CGFloat(0)
            color.getRed(&r, green:&g, blue:&b, _alpha:&a)
            self.init(Float(r),Float(g),Float(b),Float(a))
        #else
            self.init(Float(color.redComponent),Float(color.greenComponent),Float(color.blueComponent),Float(color.alphaComponent))
        #endif
    }
    
    public init(colors:[String]){
        self.init(colors[0].floatValue,colors[1].floatValue,colors[2].floatValue,colors[3].floatValue)
    }
}
