//
//  IMPGaussianDerivative.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 24.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPGaussianDerivativeEdges: IMPFilter{
    
    public var pitch:Int = 1 {
        didSet {
            dirty = true
        }
    }
    
    public override func configure(complete:CompleteHandler?) {
        extendName(suffix: "GaussianDerivativeEdges")
        add(function: gaussianDerivative){ (source) in
            complete?(source)
        }
    }
    lazy var gaussianDerivative:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_gaussianDerivativeEdge")
        f.optionsHandler = { (function, command, input, output) in
            var p = uint(self.pitch)
            command.setBytes(&p,length:MemoryLayout<uint>.size,index:0)
        }
        return f
    }()
}
