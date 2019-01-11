//
//  IMPWhiteBalance.swift
//  Pods
//
//  Created by denis svinarchuk on 05.09.17.
//
//

import Foundation
import Accelerate

public class IMPWhiteBalanceFilter: IMPFilter {
    
    public static let defaultAdjustment = IMPAdjustment( blending: IMPBlending(mode: .normal, opacity: 1))

    public var temperature:Float = 5000.0 { 
        didSet { 
            //_temperature = temperature < 5000.0 ? 0.0004 * (temperature - 5000.0) : 0.00006 * (temperature - 5000.0)
            dirty = true
        } 
    }
    public var tint:Float = 0.0 { didSet { dirty = true } }
        
    public var adjustment:IMPAdjustment = defaultAdjustment { didSet{ dirty = true } }

    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "White Balance")
        super.configure()
        temperature = 5000.0
        add(function: kernel) { (source) in
            complete?(source)
        }
    }
    
    private lazy var kernel:IMPFunction = {
        var f = IMPFunction(context: self.context, kernelName: "kernel_adjustWhiteBalance")
        f.optionsHandler = { (function, command, input, output) in
            command.setBytes(&self.temperature,  length:MemoryLayout.stride(ofValue: self.temperature), index:0)
            command.setBytes(&self.tint,         length:MemoryLayout.stride(ofValue: self.tint),         index:1)
            command.setBytes(&self.adjustment,   length:MemoryLayout.stride(ofValue: self.adjustment),   index:2)
        }        
        return f
    }()
        
}
