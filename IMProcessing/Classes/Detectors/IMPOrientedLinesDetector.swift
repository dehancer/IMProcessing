//
//  IMPLinesDetector.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 25.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal


public extension IMPFilter{
    @discardableResult public func addObserver<T:IMPOrientedLinesDetector>(lines observer: @escaping IMPOrientedLinesDetector.LinesListObserver) -> T {
        (self as! IMPOrientedLinesDetector).linesObserverList.append(observer)
        return self as! T
    }
}

public class IMPOrientedLinesDetector: IMPHoughSpaceDetector {
    
    public typealias LinesListObserver = ((_ horisontal: [IMPPolarLine], _ vertical: [IMPPolarLine], _ imageSize:NSSize) -> Void)
        
    /// Radius of region to explore lines orientation
    public var radius:Int = 8 {
        didSet{
            erosion.dimensions = (radius,radius)
            dilation.dimensions = (radius,radius)
            dirty = true
        }
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        
        erosion.dimensions = (radius,radius)
        dilation.dimensions = (radius,radius)
        
        extendName(suffix: "LinesDetector")
        super.configure()
        
        updateSettings()
        
        func linesHandlerCallback(){
            guard let size = edgesImage?.size else { return }
            let h = getLines(accum: getGPULocalMaximums(maximumsCountHorizonBuffer,maximumsHorizonBuffer), size:size)
            let v = getLines(accum: getGPULocalMaximums(maximumsCountVerticalBuffer,maximumsVerticalBuffer), size:size)
            if h.count > 0 || v.count > 0 {
                for l in linesObserverList {
                    l(h, v, size)
                }
            }
        }
        
        add(filter: dilation)
        add(filter: erosion)
        
        add(filter:sobelEdges) { (result) in
            self.edgesImage = result
            self.updateSettings()
        }
        
        add(function:houghTransformKernel)
        
        add(function:houghSpaceLocalMaximumsKernel) { (result) in
            linesHandlerCallback()
            complete?(result)
        }
    }
    

    internal override func updateSettings() {
        super.updateSettings()
        accumHorizonBuffer = self.accumBufferGetter()
        accumVerticalBuffer = self.accumBufferGetter()
        
        maximumsHorizonBuffer = self.maximumsBufferGetter()
        maximumsVerticalBuffer = self.maximumsBufferGetter()
        
        maximumsCountHorizonBuffer = self.context.device.makeBuffer(length: MemoryLayout<uint>.size,
                                                                    options: .storageModeShared)!
        maximumsCountVerticalBuffer = self.context.device.makeBuffer(length: MemoryLayout<uint>.size,
                                                                     options: .storageModeShared)!
        
        houghSpaceLocalMaximumsKernel.threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        houghSpaceLocalMaximumsKernel.preferedDimension =  MTLSize(width: self.regionSize, height: self.regionSize, depth: 1)
    }
    

    private lazy var accumHorizonBuffer:MTLBuffer? = self.accumBufferGetter()
    private lazy var accumVerticalBuffer:MTLBuffer? = self.accumBufferGetter()
    
    private lazy var maximumsHorizonBuffer:MTLBuffer? = self.maximumsBufferGetter()
    private lazy var maximumsVerticalBuffer:MTLBuffer? = self.maximumsBufferGetter()
    
    private lazy var maximumsCountHorizonBuffer:MTLBuffer? = self.context.device.makeBuffer(length: MemoryLayout<uint>.size, options: .storageModeShared)
    private lazy var maximumsCountVerticalBuffer:MTLBuffer? = self.context.device.makeBuffer(length: MemoryLayout<uint>.size, options: .storageModeShared)
    
    private lazy var regionInBuffer:MTLBuffer  = self.context.makeBuffer(from: IMPRegion())
    
    private lazy var erosion:IMPMorphology = IMPErosion(context: self.context)
    private lazy var dilation:IMPMorphology = IMPDilation(context: self.context)

    private lazy var houghTransformKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_houghTransformAtomicOriented")
        
        f.optionsHandler = { (function, command, input, output) in
            
            command.setBuffer(self.accumHorizonBuffer,     offset: 0, index: 0)
            command.setBuffer(self.accumVerticalBuffer,     offset: 0, index: 1)
            command.setBytes(&self.numrho,    length: MemoryLayout.size(ofValue: self.numrho),   index: 2)
            command.setBytes(&self.numangle,  length: MemoryLayout.size(ofValue: self.numangle), index: 3)
            command.setBytes(&self.rhoStep,   length: MemoryLayout.size(ofValue: self.rhoStep),  index: 4)
            command.setBytes(&self.thetaStep, length: MemoryLayout.size(ofValue: self.thetaStep),index: 5)
            command.setBytes(&self.minTheta,  length: MemoryLayout.size(ofValue: self.minTheta), index: 6)
            command.setBuffer(self.regionInBuffer,  offset: 0, index: 7)
        }
        
        return f
    }()
    
    private lazy var houghSpaceLocalMaximumsKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_houghSpaceLocalMaximumsOriented")
        
        f.optionsHandler = { (function, command, input, output) in
            
            command.setBuffer(self.accumHorizonBuffer,         offset: 0, index: 0)
            command.setBuffer(self.accumVerticalBuffer,        offset: 0, index: 1)
            command.setBuffer(self.maximumsHorizonBuffer,      offset: 0, index: 2)
            command.setBuffer(self.maximumsVerticalBuffer,     offset: 0, index: 3)
            command.setBuffer(self.maximumsCountHorizonBuffer, offset: 0, index: 4)
            command.setBuffer(self.maximumsCountVerticalBuffer,offset: 0, index: 5)
            
            command.setBytes(&self.numrho,    length: MemoryLayout.size(ofValue: self.numrho),   index: 6)
            command.setBytes(&self.numangle,  length: MemoryLayout.size(ofValue: self.numangle), index: 7)
            command.setBytes(&self.threshold, length: MemoryLayout.size(ofValue: self.threshold), index: 8)
        }
        
        return f
    }()
    
    private lazy var sobelEdges:IMPSobelEdgesGradient = IMPSobelEdgesGradient(context: self.context)
    
    private func getGPULocalMaximums(_ countBuff:MTLBuffer?, _ maximumsBuff:MTLBuffer?) -> [uint2] {
        
        guard let maximumsBuff = maximumsBuff else {return []}
        guard let countBuff = countBuff else {return []}
        
        let count = Int(countBuff.contents().bindMemory(to: uint.self,
                                                        capacity: MemoryLayout<uint>.size).pointee)
        var maximums = [uint2](repeating:uint2(0), count:  count)
        memcpy(&maximums, maximumsBuff.contents(), MemoryLayout<uint2>.size * count)
        return maximums.sorted { return $0.y>$1.y }
    }
    
    
    fileprivate lazy var linesObserverList = [LinesListObserver]()
}
