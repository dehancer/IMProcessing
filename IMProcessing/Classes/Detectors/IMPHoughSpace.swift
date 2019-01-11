//
//  IMPHoughSpace.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 13/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPHoughSpace {
    
    
    public let imageWidth:Int
    public let imageHeight:Int
    public let bytesPerRow:Int
    
    public let rhoStep:Float
    public let thetaStep:Float
    public let minTheta:Float
    public let maxTheta:Float
    
    public var linesMax:Int = 25
    public var threshold:Int = 100

    public init(image:UnsafeMutablePointer<UInt8>,
                bytesPerRow:Int,
                width:Int,
                height:Int,
                rhoStep:Float = 1,
                thetaStep:Float = Float.pi/180,
                minTheta:Float = 0,
                maxTheta:Float = Float.pi ) {
        
        self.bytesPerRow = bytesPerRow
        
        imageWidth = width
        imageHeight = height

        self.rhoStep = rhoStep
        self.thetaStep = thetaStep
        self.minTheta = minTheta
        self.maxTheta = maxTheta
        
        transform(image: image, rho: rhoStep, theta: thetaStep, min_theta: minTheta, max_theta: maxTheta)
    }

    public init(points:[float2],
                width:Int,
                height:Int,
                rhoStep:Float = 2,
                thetaStep:Float = Float.pi/180 * 2,
                minTheta:Float = 0,
                maxTheta:Float = Float.pi/2 ) {
        
        self.bytesPerRow = width
        
        imageWidth = width
        imageHeight = height
        
        self.rhoStep = rhoStep
        self.thetaStep = thetaStep
        self.minTheta = minTheta
        self.maxTheta = maxTheta
        
        transform(points: points, rho: rhoStep, theta: thetaStep, min_theta: minTheta, max_theta: maxTheta)
    }
    

    
    private func updateSettings() {
        numangle = round((self.maxTheta - self.minTheta) / self.thetaStep).int
        _accum = [Int](repeating:0, count:(numangle+2) * (numrho+2))
    }
    
    //
    // https://github.com/opencv/opencv/blob/master/modules/imgproc/src/hough.cpp
    //
    
    private var _accum = [Int]()
    
    var numangle:Int = 0 {
        didSet{
            let n = round((self.maxTheta - self.minTheta) / self.thetaStep).int
            
            let  irho:Float =  1 / self.rhoStep
            
            var ang = self.minTheta
            for n in 0..<n {
                self._tabSin[n] = sin(ang) * irho
                self._tabCos[n] = cos(ang) * irho
                ang += self.thetaStep
            }
        }
    }
    
    private lazy var numrho:Int   = round(((self.imageWidth.float + self.imageHeight.float) * 2 + 1) / self.rhoStep).int
    private lazy var _tabSin:[Float] = [Float](repeating:0, count:self.numangle)
    private lazy var _tabCos:[Float] = [Float](repeating:0, count:self.numangle)

    private func transform(image:UnsafeMutablePointer<UInt8>, rho:Float, theta:Float, min_theta:Float, max_theta:Float) {
        
        // stage 1. fill accumulator
                
        updateSettings()
        
        for j in stride(from: 0, to: imageWidth, by: 1){
            for i in stride(from: 0, to: imageHeight, by: 1){
                
                if image[i * bytesPerRow + j * 4] < 128 { continue }
                
                for n in 0..<numangle {
                    
                    var r = round( j.float * _tabCos[n] + i.float * _tabSin[n] )
                    r += (numrho.float - 1) / 2
                    
                    let index = (n+1) * (numrho+2) + r.int+1
                    _accum[index] += 1
                }
            }
        }
    }
    
    private func transform(points:[float2], rho:Float, theta:Float, min_theta:Float, max_theta:Float) {
        
        // stage 1. fill accumulator
        
        updateSettings()
        
        for p in points{
            for n in 0..<numangle {
                let x = p.x * imageWidth.float
                let y = p.y * imageHeight.float
                var r = round( x * _tabCos[n] + y * _tabSin[n] )
                
                r += (numrho.float - 1) / 2
                
                let index = (n+1) * (numrho+2) + r.int+1
                _accum[index] += 1
            }
        }
    }
    
    public func getLocalMaximums(threshold:Int = 50) -> [uint2] /*[(index:Int,bins:Int)]*/ {
        // stage 2. find local maximums
        var _sorted_accum = [uint2]()
        
        for r in stride(from: 0, to: numrho, by: 1) {
            for n in stride(from: 0, to: numangle, by: 1){
                
                let base = (n+1) * (numrho+2) + r+1
                let bins = _accum[base]
                if( bins > threshold &&
                    bins > _accum[base - 1] && bins >= _accum[base + 1] &&
                    bins > _accum[base - numrho - 2] && bins >= _accum[base + numrho + 2] ){
                }
                _sorted_accum.append(uint2(UInt32(base),UInt32(bins)))
            }
        }
        
        // stage 3. sort
        return _sorted_accum.sorted { return $0.y>$1.y }
    }
    
    public func getPoint(from space:  [(index:Int,bins:Int)], at index: Int) -> (rho:Float,theta:Float,capcity:Int) {
        
        let scale:Float = 1/(numrho.float+2)

        let idx = space[index].index.float
        let n = floorf(idx * scale) - 1
        let f = (n+1) * (numrho.float+2)
        let r = idx - f - 1
        
        let rho = (r - (numrho.float - 1) * 0.5) * rhoStep
        let theta = minTheta + n * thetaStep
        
        return (rho,theta,space[index].bins)
    }
    
    public func getLines() -> [IMPPolarLine]  {
        
        let _sorted_accum:[uint2] = getLocalMaximums(threshold: threshold)
        
        // stage 4. store the first min(total,linesMax) lines to the output buffer
        let linesMax = min(self.linesMax, _sorted_accum.count)
        
        let scale:Float = 1/(Float(numrho)+2)
        
        var lines = [IMPPolarLine]()
        
        var i = 0
        repeat {
            
            if i > linesMax - 1 { break }
            
            let idx = Float(_sorted_accum[i].x)
            i += 1
            let n = floorf(idx * scale) - 1
            let f = (n+1) * (Float(numrho)+2)
            let r = idx - f - 1
            
            let rho = (r - (Float(numrho) - 1) * 0.5) * rhoStep
            
            let angle = minTheta + n * thetaStep
            
            let line = IMPPolarLine(rho: rho, theta: angle)
            
            lines.append(line)
            
        } while lines.count <= linesMax && i <= linesMax
        
        return lines
    }

}
