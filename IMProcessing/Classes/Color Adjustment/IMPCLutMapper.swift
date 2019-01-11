//
//  IMPCLutMapper.swift
//  IMProcessing
//
//  Created by denis svinarchuk on 30.05.2018.
//

import Foundation

public class IMPCLutMapper:IMPContextProvider{
    
    public var reference:[float3] = [] {
        didSet{
            if reference.count > 0 {
                _target = [float3](repeating: float3(0), count: reference.count)
            }      
        }
    }
    
    public var target:[float3] {
        return _target
    }
    
    public let context: IMPContext
    
    public init(context:IMPContext, clut:IMPCLut? = nil, complete:((_ colors:[float3])->Void)? = nil){
        self.context = context
        defer {
            if let lut = clut {
                process(clut: lut, complete: complete)
            }
        }
    }
    
    public func process(clut:  IMPCLut, complete:((_ colors:[float3])->Void)?=nil) {
        
        threadgroups.width = reference.count
        
        #if os(OSX)
        let options:MTLResourceOptions = [.storageModeShared]
        #else
        let options:MTLResourceOptions = [.storageModeShared]
        #endif
        
        let length = MemoryLayout<float3>.size * self.reference.count
        
        if referenceBuffer?.length == length {
            memcpy(referenceBuffer?.contents(), reference, length)
        }
        else {
            
            referenceBuffer = context.device.makeBuffer(
                bytes: reference,
                length: length,
                options: [])
            
            targetBuffer = context.device.makeBuffer(length: length, options: options)
        }
        
        guard let buffer = referenceBuffer else { return }
        guard let tbuffer = targetBuffer else { return }
        
        context.execute(complete: {             
            memcpy(&self._target, tbuffer.contents(), buffer.length)            
            complete?(self.target)            
        }) { (commandBuffer) in
            
            let commandEncoder = self.function.commandEncoder(from: commandBuffer)            
            
            commandEncoder.setTexture(clut.texture, index:0)
            commandEncoder.setBuffer(buffer, offset: 0, index: 0)
            commandEncoder.setBuffer(tbuffer, offset: 0, index: 1)
            
            commandEncoder.dispatchThreadgroups(self.threadgroups, threadsPerThreadgroup: self.threads)
            commandEncoder.endEncoding()            
        }        
        
    }
    public var _target:[float3] = []
    
    private lazy var function:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_clutColorMapper")    
    private var maxThreads:Int{ return function.maxThreads }    
    private lazy var threads:MTLSize = {
        return MTLSize(width: 1, height: 1,depth: 1)
    }()    
    
    private var threadgroups = MTLSizeMake(1,1,1)    
    private lazy var referenceBuffer:MTLBuffer? = nil
    private lazy var targetBuffer:MTLBuffer? = nil
    
}
