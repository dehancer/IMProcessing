//
//  IMPPosterize.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 23/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPPosterize: IMPFilter{
    
    public var levels:Float = 10 { didSet{ dirty = true } }
    
    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "IPosterize")
        super.configure()
        add(function:kernel){ (source) in
            complete?(source)
        }
    }
    
    private lazy var kernel:IMPFunction = {
        let s = IMPFunction(context: self.context, kernelName: "kernel_posterize")
        s.optionsHandler = { (function, commandEncoder, input, output) in
            commandEncoder.setBytes(&self.levels,length:MemoryLayout<Float>.size,index:0)
        }
        return s
    }()
}
