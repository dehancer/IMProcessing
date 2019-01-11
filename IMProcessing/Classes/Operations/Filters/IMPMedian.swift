//
//  IMPMedian.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 23/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

open class IMPMedian: IMPFilter {
    
    public var dimensions:Int = 3 { didSet{ dirty = true } }
    
    open override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "IMPMedian")
        super.configure()
        add(function: medianKernel){ (source) in
            complete?(source)
        }
    }
    
    private lazy var medianKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_median")

        f.optionsHandler = { (function, command, input, output) in
            var d:uint = uint(self.dimensions)
            command.setBytes(&d,length:MemoryLayout<uint>.size,index:0)
        }
        
        return f
    }()
}

open class IMPTwoPassMedian: IMPTwoPass {
    
    public var dimensions:Int = 3 { didSet{ dirty = true } }
    
    required public init(context: IMPContext, name: String?=nil) {
        super.init(context: context, kernelName: "kernel_median2pass", name: name)
    }
    
    required public init(context: IMPContext, kernelName: String, name: String?) {
        fatalError("init(context:kernelName:name:) could not been overrided")
    }
    
    open override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "IMPMedian")
        super.configure(complete:complete)
    }
    
    open override func optionsHandler(passnumber: IMPTwoPass.PassNumber,
                                      function: IMPFunction,
                                      command: MTLComputeCommandEncoder,
                                      inputTexture: MTLTexture?,
                                      outputTexture: MTLTexture?) {
        var d:uint = uint(self.dimensions)
        command.setBytes(&d,length:MemoryLayout<uint>.size,index:1)
    }
}
