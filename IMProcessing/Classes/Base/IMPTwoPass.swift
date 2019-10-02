//
//  IMPTwoPass.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 23/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import simd

open class IMPTwoPass: IMPFilter {
    
    public enum PassNumber:Int {
        case first  = 0
        case second = 1
    }
    
    open func optionsHandler(
        passnumber:PassNumber,
        function:IMPFunction,
        command:MTLComputeCommandEncoder,
        inputTexture:MTLTexture?,
        outputTexture:MTLTexture?
        ){}

//    public typealias Dimensions = (width:Int,height:Int)
//
//    public var dimensions:Dimensions = (width:3,height:3) {
//        didSet{
//            dirty = true
//        }
//    }
    
    open override var source: IMPImageProvider? {
        didSet{
            updateSize()
        }
    }
    
    public override var destinationSize: NSSize? {
        didSet{
            updateSize()
        }
    }
    
    required public init(context: IMPContext, kernelName:String, name: String? = nil) {
        self.kernelName = kernelName
        super.init(context: context)
    }
    
    public required init(context: IMPContext, name: String?) {
        fatalError("init(context:name:) has not been implemented")
    }
    
    open override func configure(complete:CompleteHandler?=nil) {
        super.configure()
        add(function: horizontalKernel)
            .add(function: verticalKernel){ (source) in
                complete?(source)
        }
    }
    
    private var kernelName:String
    
    func updateSize()  {
        if let newSize = destinationSize ?? source?.size {
            
            var factor = float2(1/newSize.width.float, 0)
            memcpy(hTexelSizeBuffer.contents(), &factor, hTexelSizeBuffer.length)
            
            factor = float2(0, 1/newSize.height.float)
            memcpy(vTexelSizeBuffer.contents(), &factor, vTexelSizeBuffer.length)
        }
    }
    
    lazy var hTexelSizeBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<float2>.size, options: [])!
    lazy var vTexelSizeBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<float2>.size, options: [])!
    
    private lazy var horizontalKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: self.kernelName)
        
        f.optionsHandler = { [weak self]  (function, commandEncoder, input, output) in
            guard let self = self else { return }
            commandEncoder.setBuffer(self.hTexelSizeBuffer, offset: 0, index: 0)
            self.optionsHandler(passnumber: .first,
                                function: function,
                                command: commandEncoder,
                                inputTexture: input,
                                outputTexture: output)
        }
        
        return f
    }()
    
    private lazy var verticalKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: self.kernelName)
        f.optionsHandler = {  [weak self] (function, commandEncoder, input, output) in
            
            guard let self = self else { return }
            
            //var d:uint = uint(self.dimensions.height)
            commandEncoder.setBuffer(self.vTexelSizeBuffer, offset: 0, index: 0)
            //commandEncoder.setBytes(&d,length:MemoryLayout<uint>.size,at:1)
            self.optionsHandler(passnumber: .first,
                                function: function, 
                                command: commandEncoder, 
                                inputTexture: input, 
                                outputTexture: output)
        }
        return f
    }()
    
}
