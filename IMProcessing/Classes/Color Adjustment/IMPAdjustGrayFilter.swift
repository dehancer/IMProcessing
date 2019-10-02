//
//  IMPStretchingFilter.swift
//  Pods
//
//  Created by denis svinarchuk on 11.09.17.
//
//

import Foundation
import Accelerate

public class IMPAdjustGrayFilter:IMPFilter{
    
    public static let defaultAdjustment = IMPAdjustment(
        blending: IMPBlending(mode: .normal, opacity: 1))
    
    public var dominantColor:float3 = float3(repeating: 0.5) { didSet{ dirty = true } }
    
    public var adjustment:IMPAdjustment = defaultAdjustment { didSet{ dirty = true } }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Gray Correction Filter")
        super.configure()
        add(function: kernel) { (dest) in
            complete?(dest)
        }
    }
    
    private lazy var kernel:IMPFunction = {
        var f = IMPFunction(context: self.context, kernelName: "kernel_adjustGray")
        f.optionsHandler = { [weak self] (function, command, input, output) in
            guard let self = self else { return }
            command.setBytes(&self.dominantColor, length:MemoryLayout.size(ofValue: self.dominantColor),index:0)
            command.setBytes(&self.adjustment, length:MemoryLayout.size(ofValue: self.adjustment),index:1)
        }
        return f
    }()    
    
}
