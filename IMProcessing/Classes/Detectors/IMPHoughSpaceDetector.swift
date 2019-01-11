//
//  IMPHoughSpaceDetector.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 27/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//


#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import Metal

public class IMPHoughSpaceDetector: IMPDetector {
    
    public override var maxSize:CGFloat? { didSet{ updateSettings(); dirty = true } }
    
    public var rhoStep:Float   = 1 { didSet{updateSettings()} }
    
    public var thetaStep:Float = Float.pi/180.float{ didSet{updateSettings()} }
    
    public var minTheta:Float  = 0 { didSet{updateSettings()} }
    
    public var maxTheta:Float  = Float.pi{ didSet{updateSettings()} }
    
    public var threshold:Int = 32 { didSet{dirty = true} }
    
    public var linesMax:Int = 100 { didSet{dirty = true} }
    
    internal var edgesImage:IMPImageProvider?
    
    internal func updateSettings() {
        numangle = UInt32(round((maxTheta - minTheta) / thetaStep))
        if let size = edgesImage?.cgsize {
            numrho = UInt32(round(((size.width.float + size.height.float) * 2 + 1) / rhoStep))
            accumSize = (numangle+2) * (numrho+2)
        }
    }
    
    public var accumSize:UInt32 = 0
    public var numangle:UInt32 = 0
    public var numrho:UInt32 = 0
    
    internal func getLines(accum _sorted_accum:[uint2], size:NSSize) -> [IMPPolarLine]  {
        
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
            
            let angle = minTheta + n * thetaStep
            let rho = (r - (Float(numrho) - 1) * 0.5) * rhoStep // sqrt(size.width*size.width+size.height*size.height).float
            
            let line = IMPPolarLine(rho: rho, theta: angle)
            
            lines.append(line)
            
        } while lines.count <= linesMax && i <= linesMax
        
        return lines
    }
    
    internal func accumBufferGetter() -> MTLBuffer? {
        //
        // to echange data should be .storageModeShared!!!!
        //
        guard accumSize>0 else {
            return nil
        }
        return context.device.makeBuffer(length: MemoryLayout<UInt32>.size * Int(accumSize), options: .storageModeShared)
    }
    
    internal func maximumsBufferGetter() -> MTLBuffer? {
        //
        // to echange data should be .storageModeShared!!!!
        //
        guard accumSize>0 else {
            return nil
        }
        return context.device.makeBuffer(length: MemoryLayout<uint2>.size * Int(accumSize), options: .storageModeShared)
    }
}
