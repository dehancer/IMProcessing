//
//  IMPColorObserver.swift
//  DehancerUIKit
//
//  Created by denis svinarchuk on 17.05.2018.
//

import Foundation
import Metal

public class IMPColorObserver:IMPFilter {
    
    public var regionSize:Float = 8 {
        didSet{            
            if oldValue != regionSize {
                dirty = true
                process()
            }
        }
    }
    
    public var centers:[float2] = [float2(0.5)] {
        didSet{
            if centers.count > 0 {
                
                //
                // TODO: optimize!
                //
                centersBuffer = makeCentersBuffer()
                colorsBuffer = makeColorsBuffer()
                
                memcpy(centersBuffer.contents(), centers, centersBuffer.length)
                _colors = [float3](repeating:float3(0), count:centers.count)
                patchColorsKernel.preferedDimension =  MTLSize(width: centers.count, height: 1, depth: 1)
                
                dirty = true                
                process()
            }
        }
    }
    
    public var colors:[float3] {
        return _colors
    }
    
    fileprivate func makeCentersBuffer() -> MTLBuffer {
        return context.device.makeBuffer(length: MemoryLayout<float2>.size * centers.count, options: [])!
    }
    
    fileprivate func makeColorsBuffer() -> MTLBuffer {
        return context.device.makeBuffer(length: MemoryLayout<float3>.size * centers.count, options: .storageModeShared)!
    }
    
    fileprivate lazy var centersBuffer:MTLBuffer = self.makeCentersBuffer()
    internal lazy var colorsBuffer:MTLBuffer = self.makeColorsBuffer()
    
    private var complete: IMPFilter.CompleteHandler?
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        
        self.complete = complete
        extendName(suffix: "Checker Color Observer")
        super.configure()
        
        patchColorsKernel.preferedDimension =  MTLSize(width: 1, height: 1, depth: 1)
        
        add(function: self.patchColorsKernel){ (source) in
            if self.centers.count > 0 {
                memcpy(&self._colors, self.colorsBuffer.contents(), self.colorsBuffer.length)
            }
            if let s = self.source {
                self.complete?(s)
            }
        }
    }
    
    private lazy var patchColorsKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_patchColors")
        f.optionsHandler = { [weak self] (function,command,source,destination) in
            
            guard let self = self else { return }
            
            if self.centers.count > 0 {
                command.setBuffer(self.centersBuffer,  offset: 0, index: 0)
                command.setBuffer(self.colorsBuffer,   offset: 0, index: 1)
                command.setBytes(&self.regionSize, length:MemoryLayout.size(ofValue: self.regionSize), index:2)                
            }
        }
        return f
    }()
    
    private var _colors:[float3] = []
}

