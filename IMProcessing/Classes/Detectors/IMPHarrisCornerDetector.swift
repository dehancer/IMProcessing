//
//  IMPHarrisCornerDetector.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import Accelerate

/** Harris corner detector
 
 First pass: reduce to luminance and take the derivative of the luminance texture (GPUImageXYDerivativeFilter)
 
 Second pass: blur the derivative (GaussianBlur)
 
 Third pass: apply the Harris corner detection calculation
 
 This is the Harris corner detector, as described in
 C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.
 
 Sources:  https://github.com/BradLarson/GPUImage2
 
 */


@discardableResult public func --><T:IMPHarrisCornerDetector>(filter:T, action: @escaping ((_ corners: [IMPCorner], _ imageSize:NSSize) -> Void) ) -> T {
    filter.addObserver(newSource:{ (source) in
        filter.context.runOperation(.async, {
            filter.process()
        })
    })
    
    
    filter.addObserver(corners: { (corners, size) in
        filter.context.runOperation(.async) {
            action(corners,size)
        }
    })
    
    return filter
}


public class IMPHarrisCornerDetector: IMPDetector{
    
    public typealias PointsListObserver = ((_ corners: [IMPCorner], _ imageSize:NSSize) -> Void)
    
    public static let defaultBlurRadius:Float = 2
    public static let defaultTexelRadius:Float = 2
    
    public var blurRadius:Float {
        set{
            blurFilter.radius = newValue
            dirty = true
        }
        get { return blurFilter.radius }
    }
    
    public var texelRadius:Float {
        set{
            xyDerivative.texelRadius = newValue
            dirty = true
        }
        get { return xyDerivative.texelRadius }
    }
    
    public var sensitivity:Float {
        set{
            harrisCorner.sensitivity = newValue
        }
        get{ return harrisCorner.sensitivity }
    }
    
    
    public var threshold:Float {
        set {
            nonMaximumSuppression.threshold = newValue
        }
        get{ return nonMaximumSuppression.threshold }
    }
    
   
    public var pointsMax:Int = 4096 { didSet{ pointsBuffer = self.pointsBufferGetter() } }

    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "HarrisCornerDetector")
        
        super.configure()
        
        blurRadius  = IMPHarrisCornerDetector.defaultBlurRadius
        sensitivity = IMPHarrisCorner.defaultSensitivity
        threshold   = IMPNonMaximumSuppression.defaultThreshold
        texelRadius = IMPHarrisCornerDetector.defaultTexelRadius
        
        pointsScannerKernel.threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        pointsScannerKernel.preferedDimension =  MTLSize(width: regionSize, height: regionSize, depth: 1)
    
        add(filter: xyDerivative) { (source) in
            self.derivativeTexture = source.texture
        }
        
        add(filter: blurFilter)
        add(filter: harrisCorner)
        add(filter: nonMaximumSuppression)
        add(function: pointsScannerKernel) { (result) in
            self.readCorners(result)
            complete?(result)
        }
    }
    
    fileprivate var derivativeTexture:MTLTexture?
    
    func pointsBufferGetter() -> MTLBuffer {
        //
        // to echange data should be .storageModeShared!!!!
        //
        return context.device.makeBuffer(length: MemoryLayout<IMPCorner>.size * Int(pointsMax), options: .storageModeShared)!
    }
    
    fileprivate lazy var pointsBuffer:MTLBuffer = self.pointsBufferGetter()
    fileprivate lazy var pointsCountBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<uint>.size, options: .storageModeShared)!
    
    lazy var edgeDetector:IMPGaussianDerivativeEdges = IMPGaussianDerivativeEdges(context: self.context)

    private lazy var xyDerivative:IMPXYDerivative = IMPXYDerivative(context: self.context)
    private lazy var blurFilter:IMPGaussianBlur = IMPGaussianBlur(context: self.context)
    private lazy var harrisCorner:IMPHarrisCorner = IMPHarrisCorner(context: self.context)
    private lazy var nonMaximumSuppression:IMPNonMaximumSuppression = IMPNonMaximumSuppression(context: self.context)
    
    private lazy var pointsScannerKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_pointsScanner")
        
        f.optionsHandler = { (function, command, input, output) in
            
            memset(self.pointsCountBuffer.contents(),0,MemoryLayout<uint>.size)
            
            command.setBuffer(self.pointsBuffer,       offset: 0, index: 0)
            command.setBuffer(self.pointsCountBuffer,  offset: 0, index: 1)
            
            if let texture = self.derivativeTexture {
                command.setTexture(texture, index: 2)
            }

            var mmx = uint(self.pointsMax)
            command.setBytes(&mmx, length: MemoryLayout.size(ofValue: mmx),   index: 2)
        }
        
        return f
    }()
    
    fileprivate func getPoints(_ countBuff:MTLBuffer, _ maximumsBuff:MTLBuffer) -> [IMPCorner] {
        
        let count = Int(countBuff.contents().bindMemory(to: uint.self,
                                                        capacity: MemoryLayout<uint>.size).pointee)
        
        var maximums = [IMPCorner](repeating:IMPCorner(), count:  count)
        memcpy(&maximums, maximumsBuff.contents(), MemoryLayout<IMPCorner>.size * count)
        return maximums
    }

    fileprivate func readCorners(_ destination: IMPImageProvider) {
        
        guard let size = destination.size else { return }
        let points = getPoints(pointsCountBuffer,pointsBuffer)
        for o in cornersObserverList {
            o(points,size)
        }
        
    }
    
    public func addObserver(corners observer: @escaping PointsListObserver) {
        cornersObserverList.append(observer)
    }
    
    private lazy var cornersObserverList = [PointsListObserver]()
}
