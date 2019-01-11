//
//  IMPTpsCommonTransform.swift
//  CryptoSwift
//
//  Created by denn on 15.08.2018.
//

import AppKit
import simd

private func convert<T>(count: Int, data: UnsafePointer<T>) -> [T] {
    let buffer = UnsafeBufferPointer(start: data, count: count);
    return Array(buffer)
}

public class IMPTpsCLutTransform: IMPCLutTransform {
    public typealias Vector = float3
    public typealias Controls=IMPControlPoints<Vector>
    
    public var lambda:Float = 1 {
        didSet{
            dirty = true
        }
    }
    
    
    /// Normalized control points, e.i. belong to [0,1]
    public var controls:Controls = Controls(p: [], q: []){
        didSet{
            
            var cp = controls.p
            var cq = controls.q
            let count = Int32(cp.count)
            let length = MemoryLayout<Vector>.size * cp.count
            
            let tps = IMPTpsSolver3D(&cp, destination: &cq, count: count, lambda:lambda)
            
            let wcount = tps.weightsCount
            let wsize = wcount * MemoryLayout<Vector>.size
            let weights:[float3] = convert(count: wcount, data: tps.weights)
            
            if self.weightBuffer.length == length {
                memcpy(self.weightBuffer.contents(), weights, wsize)
                memcpy(self.qBuffer.contents(), self.controls.q, length)
            }
            else {
                
                self.weightBuffer = self.context.device.makeBuffer(
                    bytes: weights,
                    length: wsize,
                    options: [])!
                
                self.qBuffer = self.context.device.makeBuffer(
                    bytes: self.controls.q,
                    length: length,
                    options: [])!
            }
            
            dirty = true
        }
    }
    
    public var kernelName:String {
        return "-"
    }
    
    internal lazy var weightBuffer:MTLBuffer = self
        .context
        .device
        .makeBuffer(length: 4*MemoryLayout<Vector>.size, options:[])!
    
    internal lazy var qBuffer:MTLBuffer = self
        .context
        .device
        .makeBuffer(length: 4*MemoryLayout<Vector>.size, options:[])!
}
