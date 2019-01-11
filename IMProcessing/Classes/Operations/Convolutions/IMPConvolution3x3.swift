//
//  IMPConvolution3x3.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 27/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import simd

public class IMPConvolution3x3: IMPFilter {
    
    open func kernels() -> [float3x3] { return [float3x3([float3(1),float3(1),float3(1)])] }
    
    public required init(context: IMPContext, name: String?=nil, functionName: String) {
        self.functionName = functionName
        super.init(context: context, name: name)
    }
    
    public required init(context: IMPContext, name: String?=nil) {
        self.functionName = "kernel_convolutions3x3"
        super.init(context: context, name: name)
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "IMPConvolution3x3" + ":" + functionName)
        super.configure()
        kernelMatrices = kernels()
                
        add(function:convolution){ (source) in
            complete?(source)
        }
    }
    
    open func optionsHandler(shader:IMPFunction, command:MTLComputeCommandEncoder, inputTexture:MTLTexture?, outputTexture:MTLTexture?){}
    
    private let functionName: String
    private var kernelMatrices = [float3x3([float3(1,0,0),float3(0,1,0),float3(0,0,1)])] {
        didSet{
            matrixBuffers = [MTLBuffer]()
            for k in kernelMatrices {
                let buffer = context.makeBuffer(from: k)
                matrixBuffers.append(buffer)
            }
            
            matrixBufferOffsets = [Int](repeating: 0, count: self.matrixBuffers.count)
        }
    }
    
    private lazy var matrixBufferOffsets:[Int] = [Int](repeating: 0, count: self.matrixBuffers.count)
    private lazy var matrixBuffers:[MTLBuffer?] = [self.context.makeBuffer(from: self.kernelMatrices[0])]
    
    private lazy var convolution:IMPFunction = {
        let s = IMPFunction(context: self.context, kernelName: self.functionName)
        
        s.optionsHandler = { (shader, commandEncoder, input, output) in
            commandEncoder.setBuffers(self.matrixBuffers, offsets: self.matrixBufferOffsets, range: 0..<self.matrixBuffers.count)
            self.optionsHandler(shader: shader, command: commandEncoder, inputTexture: input, outputTexture: output)
        }
        return s
    }()
}
