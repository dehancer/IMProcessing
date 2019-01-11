//
//  IMPHoughLinesDetector.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 11.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

fileprivate class IMPHoughSpaceCannyEdge:IMPCannyEdges{}

public class IMPHoughLinesDetector: IMPHoughSpaceDetector {
    
    public typealias LinesListObserver = ((_ lines: [IMPPolarLine], _ imageSize:NSSize) -> Void)

    public func addObserver(lines observer: @escaping LinesListObserver) {
        linesObserverList.append(observer)
    }

    public var blurRadius:Float {
        set{
            cannyEdge.blurRadius = newValue
            dirty = true
        }
        get { return cannyEdge.blurRadius}
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        
        cannyEdge.blurRadius = 2
        
        extendName(suffix: "HoughLinesDetector")
        super.configure()
        
        updateSettings()
        
        func linesHandlerCallback(){
            guard let size = edgesImage?.size else { return }
            let lines = getLines(accum: getGPULocalMaximums(maximumsCountBuffer,maximumsBuffer), size:size)
            if lines.count > 0 {
                for l in linesObserverList {
                    l(lines, size)
                }
            }
        }

        add(filter:cannyEdge) { (result) in
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
        accumBuffer = self.accumBufferGetter()
        
        maximumsBuffer = self.maximumsBufferGetter()
        
        houghSpaceLocalMaximumsKernel.threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        houghSpaceLocalMaximumsKernel.preferedDimension =  MTLSize(width: self.regionSize, height: self.regionSize, depth: 1)
        
        maximumsCountBuffer = self.context.device.makeBuffer(length: MemoryLayout<uint>.size,
                                                             options: .storageModeShared)!
    }
    
    
    private lazy var accumBuffer:MTLBuffer? = self.accumBufferGetter()
    private lazy var maximumsBuffer:MTLBuffer? = self.maximumsBufferGetter()
    private lazy var maximumsCountBuffer:MTLBuffer? = self.context.device.makeBuffer(length: MemoryLayout<uint>.size, options: .storageModeShared)!
    private lazy var regionInBuffer:MTLBuffer?  = self.context.makeBuffer(from: IMPRegion())
    
    private lazy var houghTransformKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_houghTransformAtomic")
        
        f.optionsHandler = { (function, command, input, output) in
            
            command.setBuffer(self.accumBuffer,     offset: 0, index: 0)
            command.setBytes(&self.numrho,    length: MemoryLayout.size(ofValue: self.numrho),   index: 1)
            command.setBytes(&self.numangle,  length: MemoryLayout.size(ofValue: self.numangle), index: 2)
            command.setBytes(&self.rhoStep,   length: MemoryLayout.size(ofValue: self.rhoStep),  index: 3)
            command.setBytes(&self.thetaStep, length: MemoryLayout.size(ofValue: self.thetaStep),index: 4)
            command.setBytes(&self.minTheta,  length: MemoryLayout.size(ofValue: self.minTheta), index: 5)
            command.setBuffer(self.regionInBuffer,  offset: 0, index: 6)
        }
        
        return f
    }()
    
    private lazy var houghSpaceLocalMaximumsKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_houghSpaceLocalMaximums")
        f.optionsHandler = { (function, command, input, output) in
            
            command.setBuffer(self.accumBuffer,         offset: 0, index: 0)
            command.setBuffer(self.maximumsBuffer,      offset: 0, index: 1)
            command.setBuffer(self.maximumsCountBuffer, offset: 0, index: 2)
            
            command.setBytes(&self.numrho,    length: MemoryLayout.size(ofValue: self.numrho),   index: 3)
            command.setBytes(&self.numangle,  length: MemoryLayout.size(ofValue: self.numangle), index: 4)
            command.setBytes(&self.threshold, length: MemoryLayout.size(ofValue: self.threshold), index: 5)
        }
        
        return f
    }()
    
    private lazy var cannyEdge:IMPCannyEdges = IMPCannyEdges(context: self.context)
    

    private func getGPULocalMaximums(_ countBuff:MTLBuffer?, _ maximumsBuff:MTLBuffer?) -> [uint2] {
        
        guard let maximumsBuff = maximumsBuff else {return []}
        guard let countBuff = countBuff else {return []}
        
        let count = Int(countBuff.contents().bindMemory(to: uint.self,
                                                        capacity: MemoryLayout<uint>.size).pointee)
        var maximums = [uint2](repeating:uint2(0), count:  count)
        memcpy(&maximums, maximumsBuff.contents(), MemoryLayout<uint2>.size * count)
        return maximums.sorted { return $0.y>$1.y }
    }
    
    private lazy var linesObserverList = [LinesListObserver]()
    
}
