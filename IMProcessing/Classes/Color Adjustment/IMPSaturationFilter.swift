//
//  IMPSaturationFilter.swift
//  Pods
//
//  Created by denn on 19.08.2018.
//

import Foundation

/// Image saturation filter
public class IMPSaturationFilter: IMPFilter {
    
    public static let defaultAdjustment = IMPLevelAdjustment(level: 0.5,
                                                             blending: IMPBlending(mode: .normal, opacity: 1))
    
    /// Saturation adjustment.
    /// Default level is 0.5. Level values must be within interval [0,1].
    ///
    public var adjustment:IMPLevelAdjustment = defaultAdjustment { didSet{ dirty = true } }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Saturation Filter")
        super.configure()
        add(function: kernel, complete: complete)
    }
    
    private lazy var kernel:IMPFunction = {
        var f = IMPFunction(context: self.context, kernelName: "kernel_adjustSaturation")
        f.optionsHandler = { (function, command, input, output) in
            command.setBytes(&self.adjustment,   length:MemoryLayout.stride(ofValue: self.adjustment),   index:0)
        }
        return f
    }()
}
