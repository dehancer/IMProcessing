//
//  IMPTpsFilter.swift
//  IMProcessing
//
//  Created by denn on 12.08.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import AppKit
import simd

extension IMPTpsCLutPlane {
    public func planeCoord(for color: float3) -> float2 {
        let xyz01 = IMPColorSpace.rgb.toNormalized(space, value: color)
        return float2(xyz01[self.spaceChannels.0],xyz01[self.spaceChannels.1])
    }
}

public class IMPTpsCLutPlane: IMPTpsCLutTransform {
    
    public var rgb:float3 {
        set{ reference = space.from(.rgb, value: newValue) }
        get { return space.to(.rgb, value: reference) }
    }
    
    public var reference:float3            = float3(0)   { didSet{ dirty = true } }
    
    public override var space:IMPColorSpace {
        didSet{
            reference = space.from(oldValue, value: reference);
            dirty = true            
        }
    }

    public var spaceChannels:(Int,Int) = (0,1)       { didSet{ dirty = true } }

    public override var kernelName:String {
        return "kernel_tpsPlaneTransform"
    }
    
    override public func configure(complete: IMPFilter.CompleteHandler?) {
        
        super.extendName(suffix: "TPS Plane Transform")
        super.configure(complete: nil)
        
        let ci = NSImage(color:NSColor.darkGray, size:NSSize(width: 16, height: 16))
        source = IMPImage(context: context, image: ci)
        
        let kernel = IMPFunction(context: self.context, kernelName: kernelName)
        
        kernel.optionsHandler = {(shader, commandEncoder, input, output) in
            
            commandEncoder.setBytes(&self.reference,
                                    length: MemoryLayout.size(ofValue: self.reference),
                                    index: 0)
            
            var index = self.space.index
            commandEncoder.setBytes(&index,
                                    length: MemoryLayout.size(ofValue: index),
                                    index: 1)
            
            var pIndices = uint2(UInt32(self.spaceChannels.0),UInt32(self.spaceChannels.1))
            commandEncoder.setBytes(&pIndices,
                                    length: MemoryLayout.size(ofValue: pIndices),
                                    index: 2)
            
            commandEncoder.setBuffer(self.weightBuffer,
                                     offset: 0,
                                     index: 3)
            
            commandEncoder.setBuffer(self.qBuffer,
                                     offset: 0,
                                     index: 4)
            
            var count = self.controls.p.count
            commandEncoder.setBytes(&count,
                                    length: MemoryLayout.stride(ofValue: count),
                                    index: 5)
            
        }
        
        add(function: kernel) { (image) in
            complete?(image)
        }
    }
}

private extension NSImage {
    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
        unlockFocus()
    }
}
