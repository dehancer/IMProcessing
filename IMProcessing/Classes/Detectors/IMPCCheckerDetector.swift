//
//  IMPCCheckerDetector.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPCCheckerDetector: IMPDetector {
    
    public var isDetected:Bool {
        return _isDetected
    }
    
    public var radius  = 1 {
        didSet{
            opening.dimensions = (radius,radius)
        }
    }
    public var corners = [IMPCorner]()
    public var hLines = [IMPPolarLine]()
    public var vLines = [IMPPolarLine]()
    
    public var patchGrid:IMPPatchesGrid = IMPPatchesGrid(colors:IMPPassportCC24) {
        didSet{
            dirty = true
            patchColors.dirty = true
        }
    }
    
    public var oppositThreshold:Float = 0.5
    public var nonOrientedThreshold:Float = 0.4
    
    private var complete: IMPFilter.CompleteHandler?
        
    public override func configure(complete: IMPFilterProtocol.CompleteHandler?) {
        
        self.complete = complete
        
        extendName(suffix: "PatchesDetector")
        
        harrisCornerDetector.pointsMax = 2048
        radius = 2
        
        super.configure()
        
        add(filter: opening) { (source) in
            self.sourceImage = source
            self.harrisCornerDetector.source = source
            self.harrisCornerDetector.process()
        }
        
        patchDetectorKernel.threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        
        harrisCornerDetector.addObserver { (corners:[IMPCorner], size:NSSize) in
            
            var filtered = corners.filter { (corner) -> Bool in
                
                var count = 0
                for i in 0..<4 {
                    if corner.slope[i] >= self.nonOrientedThreshold{
                        count += 1
                    }
                }
                
                if count > 2 {
                    return false
                }
                
                if corner.slope.x>=self.oppositThreshold &&
                    corner.slope.y>=self.oppositThreshold { return true }
                
                if corner.slope.y>=self.oppositThreshold &&
                    corner.slope.w>=self.oppositThreshold { return true }
                
                if corner.slope.w>=self.oppositThreshold &&
                    corner.slope.z>=self.oppositThreshold { return true }
                
                if corner.slope.z>=self.oppositThreshold &&
                    corner.slope.x>=self.oppositThreshold { return true }
                
                return false
            }
            
            filtered = filtered.map({ ( c) -> IMPCorner in
                var c = c
                c.clampDirection()
                return c
            })
            
            let w = Float(size.width)
            let h = Float(size.height)
            
            let prec:Float = 8
            
            let sorted = filtered.sorted { (c0, c1) -> Bool in
                
                var pi0 = c0.point * float2(w,h)
                var pi1 = c1.point * float2(w,h)
                
                pi0 = floor(pi0/float2(prec)) * float2(prec)
                pi1 = floor(pi1/float2(prec)) * float2(prec)
                
                let i0 = pi0.x  + (pi0.y) * w
                let i1 = pi1.x  + (pi1.y) * w
                
                return i0<i1
            }
            
            self.corners = sorted
            
            if self.corners.count > 8 {
                self.patchDetectorKernel.preferedDimension =  MTLSize(width: self.corners.count, height: 1, depth: 1)
                
                memcpy(self.cornersBuffer.contents(), self.corners, self.corners.count * MemoryLayout<IMPCorner>.size)
                
                self.patchDetector.source = self.harrisCornerDetector.source
                self.patchDetector.process()
                
                self.patchColors.source = self.sourceImage
                self.patchColors.process()
            }
            else {
                self.vLines = []
                self.hLines = []
                self.patchGrid.target.reset()
            }
        }
    }
    
    private var sourceImage:IMPImageProvider?
    
    fileprivate lazy var cornersBuffer:MTLBuffer = self.context.device.makeBuffer(
        length: MemoryLayout<IMPCorner>.size * Int(self.harrisCornerDetector.pointsMax),
        options: .storageModeShared)!
        
    private lazy var harrisCornerDetector:IMPHarrisCornerDetector = IMPHarrisCornerDetector(context:  self.context)
    private lazy var opening:IMPErosion = IMPOpening(context: self.context)
    
    private lazy var patchDetectorKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_patchScanner")
        f.optionsHandler = { (function,command,source,destination) in
            
            if let texture = self.sourceImage?.texture {
                command.setTexture(texture, index: 2)
            }
            
            command.setBuffer(self.cornersBuffer,          offset: 0, index: 0)
        }
        return f
    }()
    
    
    public var _isDetected:Bool = false
    
    private lazy var patchDetector:IMPFilter = {
        let f = IMPFilter(context:self.context)
        f.add(function: self.patchDetectorKernel){ (source) in
            
            self._isDetected = false
            guard let size = source.size else {return}
            
            memcpy(&self.corners, self.cornersBuffer.contents(), MemoryLayout<IMPCorner>.size * self.corners.count)
            self.patchGrid.corners = self.corners
            if let r = self.patchGrid.approximate(withSize: size){
                (self.hLines, self.vLines) = r
                self._isDetected = true
            }
            
            self.patchColors.centers = self.patchGrid.target.centers
        }
        
        return f
    }()

    private lazy var patchColors:IMPColorObserver = {
        let f = IMPColorObserver(context: self.context)
        
        f.addObserver(destinationUpdated: { (destination) in
            self.patchGrid.target.update(colors:f.colorsBuffer)
            if let s = f.source {
                self.complete?(s)
            }
        })        
        
        return f
    }()
    
}

