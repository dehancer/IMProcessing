//
//  IMPTpsFilter.swift
//  CryptoSwift
//
//  Created by denn on 16.08.2018.
//

import Foundation

public class IMPTpsFilter: IMPTpsCLutTransform {
    
    public static let defaultAdjustment = IMPAdjustment( blending: IMPBlending(mode: .normal, opacity: 1))
    public var adjustment:IMPAdjustment = defaultAdjustment { didSet{ dirty = true } }

    public override var kernelName:String {
        return "kernel_tpsLutTransform"
    }
    
    override public func configure(complete: IMPFilter.CompleteHandler?) {
        
        super.extendName(suffix: "TPS Filter")
        super.configure(complete: nil)
        
        let kernel = IMPFunction(context: self.context, kernelName: kernelName)
        
        kernel.optionsHandler = { [weak self] (shader, commandEncoder, input, output) in
            
            guard let self = self else {
                return
            }
            
            var index = self.space.index
            commandEncoder.setBytes(&index,
                                    length: MemoryLayout.size(ofValue: index),
                                    index: 0)
            
            commandEncoder.setBuffer(self.weightBuffer,
                                     offset: 0,
                                     index: 1)
            
            commandEncoder.setBuffer(self.qBuffer,
                                     offset: 0,
                                     index: 2)
            
            var count = self.controls.p.count
            commandEncoder.setBytes(&count,
                                    length: MemoryLayout.stride(ofValue: count),
                                    index: 3)
            
            commandEncoder.setBytes(&self.adjustment,
                                    length:MemoryLayout.stride(ofValue: self.adjustment),
                                    index:4)
            
            commandEncoder.setBytes(&self.levels,
                                    length:MemoryLayout.stride(ofValue: self.levels),
                                    index:5)
            
        }
        
        add(function: kernel) { (image) in
            complete?(image)
        }
    }
}
