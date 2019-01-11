//
//  IMPPatch.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

extension IMPCorner: Equatable {
    
    public static func ==(lhs: IMPCorner, rhs: IMPCorner) -> Bool {
        return (abs(lhs.point.x-rhs.point.x) < 0.1) && (abs(lhs.point.y-rhs.point.y) < 0.1)
    }
    
    public var left:float2  { return float2(-slope.x,0) }
    public var top:float2   { return float2(0,slope.y)  }
    public var right:float2 { return float2(slope.w,0)  }
    public var bottom:float2{ return float2(0,-slope.z) }
    
    
    public var direction:float2 {
        return left + top + right + bottom
    }
    
    public mutating func clampDirection(threshold:Float = 0.1) {
        // x - left, y - top, z - bottom, w - right
        
        let d = direction
        
        if d.x>0 && d.y<0 && length(d)>=threshold {
            slope.y = 0 //           __
            slope.x = 0 // left top |
            slope.w = 1
            slope.z = 1
        }
        if d.x<0 && d.y<0 && length(d)>=threshold {
            slope.y = 0 //           __
            slope.w = 0 // right top   |
            slope.x = 1
            slope.z = 1
        }
        if d.x<0 && d.y>0 && length(d)>=threshold {
            slope.w = 0 //
            slope.z = 0 // right bottom  __|
            slope.y = 1
            slope.x = 1
        }
        if d.x>0 && d.y>0 && length(d)>=threshold {
            slope.x = 0 //
            slope.z = 0 // left bottom |__
            slope.y = 1
            slope.w = 1
        }
    }
}

public struct IMPPatch:Equatable {
    
    public init() {}
    
    public static func ==(lhs: IMPPatch, rhs: IMPPatch) -> Bool {
        if let c0 = lhs.center, let c1 = rhs.center {
            return (abs(c0.point.x-c1.point.x) < 0.01) && (abs(c0.point.y-c1.point.y) < 0.01)
        }
        return false
    }
    
    
    public var center:IMPCorner? {
        return _center
    }
    
    public var horizon:IMPLineSegment? {
        return _horizon
    }
    
    public var vertical:IMPLineSegment? {
        return _vertical
    }
    
    public var lt:IMPCorner? {didSet{ vertices[0] = lt } }
    public var rt:IMPCorner? {didSet{ vertices[1] = rt } }
    public var rb:IMPCorner? {didSet{ vertices[2] = rb } }
    public var lb:IMPCorner? {didSet{ vertices[3] = lb } }
    
    private var _horizon: IMPLineSegment?
    private var _vertical: IMPLineSegment?
    
    private var _center:IMPCorner? {
        didSet{
            if let lt = self.lt,
                let rt = self.rt,
                let lb = self.lb,
                let rb = self.rb {
                _horizon = IMPLineSegment(p0: centerOf(lt, lb), p1: centerOf(rt, rb))
                _vertical = IMPLineSegment(p0: centerOf(lt, rt), p1: centerOf(lb, rb))
            }
        }
    }
    
    private func centerOf(_ c0:IMPCorner, _ c1:IMPCorner) -> float2 {
        return (c0.point+c1.point)/float2(2)
    }
    
    public mutating func tryReconstract() {
        
        if lt == nil {
            if let rt = self.rt,
                let rb = self.rb,
                let lb = self.lb {
                var c = IMPCorner()
                c.point.x = rt.point.x - abs(rb.point.x - lb.point.x)
                c.point.y = lb.point.y - abs(rt.point.y - rb.point.y)
                c.color = rt.color
                lt = c
            }
        }
        
        if lb == nil {
            if let rt = self.rt,
                let rb = self.rb,
                let lt = self.lt {
                var c = IMPCorner()
                c.point.x = rb.point.x - abs(lt.point.x - rt.point.x)
                c.point.y = lt.point.y + abs(rt.point.y - rb.point.y)
                c.color = lt.color
                lb = c
            }
        }
        
        if rt == nil {
            if let lb = self.lb,
                let rb = self.rb,
                let lt = self.lt {
                var c = IMPCorner()
                c.point.x = lt.point.x + abs(lb.point.x - rb.point.x)
                c.point.y = rb.point.y - abs(lt.point.y - lb.point.y)
                c.color = lt.color
                rt = c
            }
        }
        
        if rb == nil {
            if let lb = self.lb,
                let rt = self.rt,
                let lt = self.lt {
                var c = IMPCorner()
                c.point.x = lb.point.x + abs(lt.point.x - rt.point.x)
                c.point.y = rt.point.y + abs(lt.point.y - lb.point.y)
                c.color = lt.color
                rb = c
            }
        }
        
    }
    
    private func angle(_ pt1:float2, _ pt2:float2, _ pt0:float2 ) -> Float {
        let dx1 = pt1.x - pt0.x
        let dy1 = pt1.y - pt0.y
        let dx2 = pt2.x - pt0.x
        let dy2 = pt2.y - pt0.y
        return acos((dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10)).degrees
    }
    
    private var vertices:[IMPCorner?] = [IMPCorner?](repeating:nil, count:4) {
        didSet{
            var sumOfR = float2(0)
            var count = 0
            var col = float4(0)
            for i in 0..<4 {
                let v = vertices[i]
                
                if v != nil {
                    sumOfR += v!.point
                    count += 1
                    col += v!.color
                }
            }
            
            if count == 4 {
                
                var minCosine:Float = Float.greatestFiniteMagnitude //FLT_MAX
                for i in 0..<4 {
                    let a = abs(angle(vertices[i]!.point, vertices[(i+2)%4]!.point, vertices[(i+1)%4]!.point))
                    minCosine = fmin(minCosine, a)
                }
                
                if( abs(minCosine-90) <= 10 ) {
                    _center = IMPCorner(point: sumOfR/float2(4), slope: float4(1), color:  col/(float4(4)))
                }
            }
        }
    }
}

