//
//  IMProcessorKernel.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 12.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Metal
import CoreImage

//
// Render RAW to MTLTexture snippet
//
//CMSampleBufferRef rawSampleBuffer; // from your AVCapturePhotoCaptureDelegate callback
//NSDictionary* rawImageAttachments = (__bridge_transfer NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, rawSampleBuffer, kCMAttachmentMode_ShouldPropagate);
//CIContext* context = [CIContext contextWithMTLDevice:[...your device...]];
//id<MTLTexture> texture = [... initialize your textue... ]
//CIFilter* rawFilter = [CIFilter filterWithCVPixelBuffer:CMSampleBufferGetImageBuffer(rawSampleBuffer) properties:rawImageAttachments options:[... your options ...]];
//[context render:rawFilter.outputImage toMTLTexture:texture commandBuffer:[...] bounds:[...] colorSpace:[...]]


protocol IMPCoreImageRegister {
    static func register(name:String)
}

class IMPCIFilterConstructor: NSObject, CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        return IMPCIFilter()
    }
}

public class IMPCIFilter: CIFilter, IMPDestinationSizeProvider {
    
    public typealias CommandProcessor = ((
        _ commandBuffer:MTLCommandBuffer,
        _ threadgroups:MTLSize,
        _ threadsPerThreadgroup:MTLSize,
        _ sourceTexture:MTLTexture,
        _ destinationTexture:MTLTexture
        )->Void)
    
    public var context:IMPContext {
        set {
            _context = newValue
        }
        get {
            return _context
        }
    }
    
    public var preferedDimension:MTLSize?
    
    private var _context:IMPContext!// = IMPContext()
    
    public var source:IMPImageProvider?
    fileprivate lazy var destination:IMPImageProvider = IMPImage(context: self.context)
    
    public var destinationSize: NSSize? = nil
    public var inputImage: CIImage? {
        set{
            if source == nil {
                if let image = newValue {
                    source = IMPImage(context: context)
                    source?.image = image
                }
            }
            else {
                source?.image = newValue
            }
        }
        get{
            return source?.image
        }
    }
    
    override public var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "IMP Processing Filter" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
    
        ]
    }
    
    lazy public var colorSpace:CGColorSpace = {
        return IMProcessing.colorSpace.cgColorSpace
    }()
    
    lazy public var processor:CommandProcessor? = self.textureProcessor
    
    lazy public var threadsPerThreadgroup:MTLSize = MTLSize(width: 16,height: 16,depth: 1)
    
    var kernelIndex:Int? = 0
 
    open func textureProcessor(
        _ commandBuffer:MTLCommandBuffer,
        _ threadgroups:MTLSize,
        _ threadsPerThreadgroup:MTLSize,
        _ source:MTLTexture,
        _ destination:MTLTexture
        ) -> Void {
    }
    
    func processBigImage(index:Int) -> CIImage? {
        guard let processor = self.processor else { return nil}
        return processCIImage(command: processor)
    }
    
    func processImage() -> CIImage? {
        guard let processor = self.processor else { return nil}
        return processCIImage(command: processor)
    }
    
    func processCIImage(command:@escaping CommandProcessor) -> CIImage? {
        return process(command: command).image
    }
}

extension IMPCIFilter {
    
    override public var outputImage: CIImage? {
        
        if let size = source?.size,
            let index = kernelIndex {
            let msize = fmax(size.width, size.height)
            if msize > IMPContext.maximumTextureSize.cgfloat {
                return processBigImage(index: index)
            }
            else {
                return processImage()
            }
        }
        return nil
    }
    
    public func flush() {
        source?.image = nil
        source = nil
        destination.image = nil
        destinationSize = nil
    }
    

    var mtlSize:MTLSize? {
        if let size = source?.size {
            return MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
        }
        return nil
    }
    
    func process(command:@escaping CommandProcessor) -> IMPImageProvider {
                
        guard let size =  destinationSize ?? source?.size else { return IMPImage(context: context) }
        guard let format =  source?.texture?.pixelFormat else { return IMPImage(context: context) }
        
        destination.texture = destination.texture?.reuse(size: size) ?? context.make2DTexture(size: size, pixelFormat: format)
        //destination.texture = context.make2DTexture(size: size, pixelFormat: format)
                
        if let texture = destination.texture {
            process(to: texture, command: command)
        }
        
        return destination
    }
    
    func process(to destinationTexture: MTLTexture, commandBuffer buffer: MTLCommandBuffer? = nil, command: CommandProcessor? = nil){        
        
        guard let sourceTexture = source?.texture else { return }
        
        let size =  destinationTexture.cgsize
        
        var threadgroups:MTLSize
        
        let width = threadsPerThreadgroup.width
        let height = threadsPerThreadgroup.height
        
        if let dim = preferedDimension {
            threadgroups = MTLSizeMake(
                (dim.width + width - 1) / width ,
                (dim.height + height - 1) / height,
                1)

        }
        else {
            threadgroups = MTLSizeMake(
                (Int(size.width) + width - 1) / width ,
                (Int(size.height) + height - 1) / height,
                1);
        }
        
        //print("kernel grid size groups = \(threadgroups), group size = \(threadsPerThreadgroup)")
        
        if let commandBuffer = buffer {
            if let command = command{
                command(commandBuffer, threadgroups, self.threadsPerThreadgroup, sourceTexture, destinationTexture)
            }
            else {
                self.processor?(commandBuffer, threadgroups, self.threadsPerThreadgroup, sourceTexture, destinationTexture)
            }
        }
        else {
            context.execute { (commandBuffer) in
                if let command = command{
                    command(commandBuffer, threadgroups, self.threadsPerThreadgroup, sourceTexture, destinationTexture)
                }
                else {
                    self.processor?(commandBuffer, threadgroups, self.threadsPerThreadgroup, sourceTexture, destinationTexture)
                }
            }
        }
    }
}
