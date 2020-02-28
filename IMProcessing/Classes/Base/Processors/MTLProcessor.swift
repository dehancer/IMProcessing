//
//  MTLProcessor.swift
//  IMPCoreImageMTLKernel
//
//  Created by Denis Svinarchuk on 14/02/17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Metal
import CoreImage

public class IMPCoreImageMTLKernel: IMPCIFilter{
    
    private static var mutex = IMPSemaphore()
    
    override public var destinationSize: NSSize? {
        set{
            function?.destinationSize = newValue
        }
        get{
            return function?.destinationSize
        }
    }
    
    public override var preferedDimension: MTLSize? {
        set {
            function?.preferedDimension = newValue
        }
        get {
            return function?.preferedDimension
        }
    }
    
    public override var threadsPerThreadgroup: MTLSize {
        set{
            function?.threadsPerThreadgroup = newValue
        }
        get{
            return (function?.threadsPerThreadgroup ?? MTLSize(width: 16,height: 16,depth: 1))
        }
    }
    
    private static var registeredFunctionList:[IMPFunction] = [IMPFunction]()
    private static var registeredFilterList:[String:IMPCoreImageMTLKernel] = [String:IMPCoreImageMTLKernel]()
    
    //    static func register(name: String) {
    //        CIFilter.registerName(name, constructor: IMPCIFilterConstructor() as CIFilterConstructor,
    //                              classAttributes: [
    //                                kCIAttributeFilterCategories: ["IMPCoreImage"]
    //            ])
    //    }
    
    static func register(function:IMPFunction) -> IMPCoreImageMTLKernel {
        return mutex.sync {
            if let filter = registeredFilterList[function.name] {
                return filter
            }
            else {
                let filter = IMPCoreImageMTLKernel()
                if #available(iOS 10.0, *) {
                    filter.name = function.name
                } else {
                    // Fallback on earlier versions
                    fatalError("IMPCoreImageMPSUnaryKernel: ios >10.0 supports only")
                }
                filter.function = function
                filter.context = function.context
                filter.threadsPerThreadgroup = function.threadsPerThreadgroup
                registeredFilterList[function.name] = filter
                return filter
            }
        }
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        return self.function?.name == (object as? IMPCoreImageMTLKernel)?.function?.name
    }
        
    private var function: IMPFunction? {
        didSet{
            guard let f = function else {
                return
            }
            if let index = IMPCoreImageMTLKernel.registeredFunctionList.index(of: f) {
                kernelIndex = index
            }
            else {
                kernelIndex = IMPCoreImageMTLKernel.registeredFunctionList.count
                IMPCoreImageMTLKernel.registeredFunctionList.append(f)
            }
        }
    }
    
    override func processBigImage(index:Int) -> CIImage? {
        do {
            if #available(iOS 10.0, *) {
                guard let image = inputImage else { return nil }
                return try ProcessorKernel.apply(withExtent: image.extent, inputs: [image],
                                                       arguments: ["functionIndex" : index])
            } else {
                return processImage()
            }
        }
        catch let error as NSError {
            print("error = \(error)")
        }
        
        return nil
    }
        
    override public func textureProcessor(_ commandBuffer: MTLCommandBuffer,
                                   _ threadgroups: MTLSize,
                                   _ threadsPerThreadgroup: MTLSize,
                                   _ sourceTexture: MTLTexture,
                                   _ destinationTexture: MTLTexture) {
        if let kernel = function{
            IMPCoreImageMTLKernel.imageProcessor(kernel: kernel,
                                                 commandBuffer: commandBuffer,
                                                 threadgroups: threadgroups,
                                                 threadsPerThreadgroup: threadsPerThreadgroup,
                                                 input: sourceTexture,
                                                 output: destinationTexture)
        }
    }
    
    class func imageProcessor (
        kernel:IMPFunction,
        commandBuffer:MTLCommandBuffer,
        threadgroups:MTLSize,
        threadsPerThreadgroup:MTLSize,
        input:MTLTexture,
        output:MTLTexture
    )  {
        if let handler = kernel.optionsHandler {
            
            let commandEncoder =  kernel.commandEncoder(from: commandBuffer)
            
            commandEncoder.setTexture(input, index:0)
            commandEncoder.setTexture(output, index:1)
            
            handler(kernel, commandEncoder, input, output)
                        
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threadsPerThreadgroup)
            commandEncoder.endEncoding()
        }
        else if let handler = kernel.stagesHandler {
            
            handler(kernel, commandBuffer, input, output)
            
        }
    }
    
    @available(iOS 10.0, *)
    class ProcessorKernel: CIImageProcessorKernel {
        
        class func getMTLFunction(index:Int?) -> IMPFunction? {
            guard let i = index else {
                return nil
            }
            return registeredFunctionList[i]
        }
        
        override class func process(with inputs: [CIImageProcessorInput]?, arguments: [String : Any]?, output: CIImageProcessorOutput) throws {
            
            guard
            let input              = inputs?.first,
            let sourceTexture      = input.metalTexture,
            let destinationTexture = output.metalTexture,
            let commandBuffer      = output.metalCommandBuffer,
            let kernel             = ProcessorKernel.getMTLFunction(index: arguments?["functionIndex"] as? Int)
            else  {
                return
            }
            
            let width  = destinationTexture.size.width
            let height = destinationTexture.size.height
            
            let threadsPerThreadgroup = kernel.threadsPerThreadgroup
            
            var threadgroups:MTLSize
            
            if let dim = kernel.preferedDimension {
                threadgroups = MTLSizeMake(
                    (dim.width + threadsPerThreadgroup.width) / threadsPerThreadgroup.width ,
                    (dim.height + threadsPerThreadgroup.height) / threadsPerThreadgroup.height,
                    1)
            }
            else {
                threadgroups = MTLSizeMake(
                    (width + threadsPerThreadgroup.width) / threadsPerThreadgroup.width ,
                    (height + threadsPerThreadgroup.height) / threadsPerThreadgroup.height,
                    1)
            }
            
            IMPCoreImageMTLKernel.imageProcessor(kernel: kernel,
                                                 commandBuffer: commandBuffer,
                                                 threadgroups: threadgroups,
                                                 threadsPerThreadgroup: threadsPerThreadgroup,
                                                 input: sourceTexture,
                                                 output: destinationTexture)
            
        }
    }
}

