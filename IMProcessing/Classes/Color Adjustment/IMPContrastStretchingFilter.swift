//
//  IMPStretchingFilter.swift
//  Pods
//
//  Created by denis svinarchuk on 11.09.17.
//
//

import Foundation
import Accelerate

public class IMPContrastStretchingFilter:IMPFilter{
    
    public static let defaultAdjustment = IMPContrastAdjustment(
        minimum: float4([0,0,0,1]),
        maximum: float4([1,1,1,1]),
        blending: IMPBlending(mode: .luminosity, opacity: 1))
    
    public var adjustment:IMPContrastAdjustment = defaultAdjustment {didSet{
        dirty = true 
        }}
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Contrast Scretching")
        super.configure()
        add(function: kernel) { (dest) in
            complete?(dest)
        }
    }
    
    private lazy var kernel:IMPFunction = {
        var f = IMPFunction(context: self.context, kernelName: "kernel_adjustContrastStretching")
        f.optionsHandler = { (function, command, input, output) in
            command.setBytes(&self.adjustment, length:MemoryLayout.size(ofValue: self.adjustment),index:0)
        }
        return f
    }()    
    
}
