//
//  IMPPatchesGrid.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import simd

public struct IMPPatchesGrid {
    
    public typealias Patch = IMPPatch
    
    public struct Dimension {
        public let width:Int
        public let height:Int
    }
    
    public struct PatchesInfo {
        
        public let count:Int
        public var centers:[float2] { return _centers }
        public var colors:[float3] { return _colors }
        
        public init(dimension:Dimension) {
            height = dimension.height
            width = dimension.width
            count = height*width
            _centers = [float2](repeating:float2(-1), count:count)
            _colors = [float3](repeating:float3(0), count:count)
        }
        
        public mutating func update(colors: MTLBuffer?=nil,centers: MTLBuffer?=nil){
            if let c = centers {
                memcpy(&_centers, c.contents(), c.length)
            }
            
            if let c = colors {
                memcpy(&_colors, c.contents(), c.length)
            }
            
        }
        
        
        public mutating func reset() {
            _centers = [float2](repeating:float2(-1), count:count)
            _colors = [float3](repeating:float3(0), count:count)
        }
        
        public subscript(_ x:Int,_ y:Int) -> (center:float2,color:float3) {
            get {
                let center = _centers[x + y * width]
                let color = _colors[x + y * width]
                return (center,color)
            }
            set{
                _centers[x+y*width] = newValue.center
                _colors[x+y*width] = newValue.color
            }
        }
        
        public subscript(_ i:Int) -> (center:float2,color:float3) {
            get {
                let center = _centers[i]
                let color = _colors[i]
                return (center,color)
            }
            set{
                _centers[i] = newValue.center
                _colors[i] = newValue.color
            }
        }
        
        private var _centers:[float2]
        private var _colors:[float3]
        
        private let width:Int
        private let height:Int
    }
    
    public let dimension:Dimension
    public let source:[[float3]]
    
    public var target:PatchesInfo
    
    public var patches:[Patch] {
        return _patches
    }
    
    public init(colors: [[uint3]] = IMPPassportCC24) {
        //dimension = Dimension(width: colors[0].count, height: colors.count)
        //target = PatchesInfo(dimension: dimension)
        //source = colors.map({ return $0.map({ return float3(Float($0.x),Float($0.y),Float($0.z))/float3(255) }) })
        self.init(colors: colors.map({ return $0.map({ return float3(Float($0.x),Float($0.y),Float($0.z))/float3(255) }) }))
    }
    
    public init(colors: [[float3]]) {
        source = colors
        dimension = Dimension(width: colors[0].count, height: colors.count)
        target = PatchesInfo(dimension: dimension)
    }
    
    
    public var corners = [IMPCorner]() { didSet{ match() } }
    
    public func findCheckerIndex(color:float3, minDistance:Float = 20) -> (Int,Int)? {
        for i in 0..<dimension.height {
            let row  = source[i]
            for j in 0..<dimension.width {
                let cc = row[j]
                let ed = cc.euclidean_distance_lab(to: color)
                if  ed < minDistance {
                    return (j,i)
                }
            }
        }
        return nil
    }
    
    public mutating func approximate(withSize size:NSSize, minDistance:Float = 16, minTheta:Float = Float.pi/45)
        -> (
        horizon:  [IMPPolarLine],
        vertical: [IMPPolarLine]
        )?
    {
        var horizons  = [IMPPolarLine]()
        var verticals = [IMPPolarLine]()
        
        for p in patches {
            if let h = p.horizon?.polarLine(size: size)  { horizons.append(h) }
            if let v = p.vertical?.polarLine(size: size) { verticals.append(v) }
        }
        
        let horizonSorted  = horizons.sorted  { return abs($0.rho)<abs($1.rho) }
        let vdrticalSorted = verticals.sorted { return abs($0.rho)<abs($1.rho) }
        
        guard var (h,hrho,htheta) = filterClosing(horizonSorted, minDistance: minDistance, minTheta: minTheta) else { return nil }
        guard var (v,vrho,vtheta) = filterClosing(vdrticalSorted, minDistance: minDistance, minTheta: minTheta) else { return nil }
        
        let startVRho = v.first!.rho
        let startHRho = h.first!.rho
        let denom = float2(1)/float2(size.width.float,size.height.float)
        
        
        if h.count == 6 && v.count == 4 {
            // swap
            swap(&h, &v)
            swap(&hrho, &vrho)
            swap(&htheta, &vtheta)
        }
        
        
        guard h.count >= 4 && h.count < 24 else { return nil }
        guard v.count >= 6 && v.count < 24 else { return nil }
        
        for y in 0..<dimension.height {
            var hl = IMPPolarLine(rho: hrho * y.float + startHRho, theta: htheta)
            
            if h.count > y {
                hl = h[y]
            }
            else { break }
            
            for x in 0..<dimension.width {
                var vl = IMPPolarLine(rho: vrho * x.float + startVRho, theta: vtheta)
                if v.count > x {
                    vl = v[x]
                    let center = vl.intersect(with: hl)
                    target[x,y] = (center:center * denom, color:float3(0))
                }
                else { break }
            }
        }
        
        return (h,v)
    }
    
    private var _patches = [Patch]()
    
    private mutating func match(minDistance:Float = 5) {
        
        _patches.removeAll()
        
        for current in corners {
            
            if current.color.a < 0.1 {continue}
            
            let color = current.color.rgb
            
            var patch = Patch()
            
            if current.slope.w > 0 && current.slope.z > 0 {
                // rb
                patch.lt = current
            }
            else if current.slope.x > 0 && current.slope.y > 0 {
                // rb
                patch.rb = current
            }
            else if current.slope.x > 0 && current.slope.z > 0 {
                // rt
                patch.rt = current
            }
            else if current.slope.y > 0 && current.slope.w > 0 {
                // lb
                patch.lb = current
            }
            
            for next in corners {
                
                if next.point == current.point { continue }
                
                if next.color.a < 0.1 { continue }
                
                let next_color = next.color.rgb
                let ed = color.euclidean_distance_lab(to: next_color)
                
                let dist = distance(next.point, current.point)
                
                
                if ed <= minDistance {
                    
                    if current.slope.w > 0 && current.slope.z > 0 {
                        // lt
                        if patch.lt == nil {
                            patch.lt = next
                        }
                        else if distance(patch.lt!.point, current.point) > dist{
                            patch.lt = next
                        }
                    }
                    
                    if next.slope.x > 0 && next.slope.y > 0 {
                        // rb
                        if patch.rb == nil {
                            patch.rb = next
                        }
                        else if distance(patch.rb!.point, current.point) > dist{
                            patch.rb = next
                        }
                    }
                    if next.slope.x > 0 && next.slope.z > 0 {
                        // rt
                        if patch.rt == nil {
                            patch.rt = next
                        }
                        else if distance(patch.rt!.point, current.point) > dist{
                            patch.rt = next
                        }
                        
                    }
                    if next.slope.y > 0 && next.slope.w > 0 {
                        // lb
                        if patch.lb == nil {
                            patch.lb = next
                        }
                        else if distance(patch.lb!.point, current.point) > dist{
                            patch.lb = next
                        }
                    }
                    
                    if patch.center != nil {
                        break
                    }
                }
            }
            
            if patch.center == nil {
                patch.tryReconstract()
            }
            
            if patch.center != nil && !patches.contains(patch) {
                _patches.append(patch)
            }
            
        }
    }
    
    private func filterClosing(_ lines:[IMPPolarLine], minDistance:Float = 16, minTheta:Float = Float.pi/45) -> (line:[IMPPolarLine], rho:Float, theta:Float)? {
        
        guard let firstLine = lines.first else { return nil }
        var prev = firstLine
        var prevFirst:IMPPolarLine? = prev
        
        var result = [IMPPolarLine]()
        
        var minDist:Float = Float.greatestFiniteMagnitude
        
        func compareLines(_ p:IMPPolarLine, _ l:IMPPolarLine) -> Bool {
            if sign(p.rho) == sign(l.rho) {
                return abs(p.rho-l.rho)<minDistance && abs(p.theta-l.theta)<minTheta
            }
            else {
                return abs(p.rho+l.rho)<minDistance && abs(p.theta + l.theta - Float.pi)<minTheta
            }
        }
        
        for i in 1..<lines.count {
            
            let current = lines[i]
            
            if abs(current.rho - prev.rho) < minDistance {
                current.rho = (current.rho + prev.rho)/2
                current.theta = (current.theta + prev.theta)/2
                prevFirst = current
                prev = current
            }
            else {
                
                minDist = min(abs(current.rho - prev.rho),minDist)
                
                if let l = prevFirst {
                    if !result.contains(where: { (p) -> Bool in
                        return compareLines(p, l)
                    }) {
                        result.append(l)
                    }
                    prevFirst = nil
                }
                else {
                    let l = current
                    if !result.contains(where: { (p) -> Bool in
                        return compareLines(p, l)
                        
                    }) {
                        result.append(current)
                    }
                }
                
                prev = current
            }
        }
        
        func getDist(from current:IMPPolarLine, to nextPrev:IMPPolarLine, with minDist:Float) -> Float {
            var dist:Float = minDist
            if sign(nextPrev.rho) == sign(current.rho) {
                if abs(nextPrev.theta-current.theta)<minTheta {
                    dist = abs(nextPrev.rho - current.rho)
                }
            }
            else {
                if abs(nextPrev.theta + current.theta - Float.pi)<minTheta {
                    dist = abs(nextPrev.rho + current.rho)
                }
            }
            
            return dist
        }
        
        if let l = prevFirst { result.append(l) }
        
        guard let nextPrevFirst = result.first else { return nil }
        var nextPrev = nextPrevFirst
        var avrgRho:Float = 0
        var avrgTheta:Float = 0
        var count:Float = 0
        for current in result.suffix(from: 1) {
            let dist:Float = getDist(from: current, to: nextPrev, with: minDist)
            if abs(dist-minDist) <= minDistance * 2 {
                avrgRho += dist
                avrgTheta += current.theta
                count += 1
            }
            nextPrev = current
        }
        
        avrgRho /= count
        avrgTheta /= count
        
        guard avrgRho > 0 else { return nil }
        
        nextPrev = nextPrevFirst
        var gaps = [IMPPolarLine]()
        for current in result.suffix(from: 1) {
            let dist:Float = getDist(from: current, to: nextPrev, with: avrgRho)
            if abs(dist-avrgRho) > minDistance * 2 {
                for i in 0..<Int(dist/avrgRho) {
                    let l = IMPPolarLine(rho: nextPrev.rho + sign(nextPrev.rho) * avrgRho * (i.float+1), theta: avrgTheta)
                    gaps.append(l)
                }
            }
            nextPrev = current
        }
        
        result.append(contentsOf: gaps)
        result = result.sorted  { return abs($0.rho)<abs($1.rho) }
        
        return (result,avrgRho,avrgTheta)
    }
}
