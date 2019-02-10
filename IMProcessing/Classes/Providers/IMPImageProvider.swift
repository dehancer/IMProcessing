//
//  IMPImageProvider.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
    
    public typealias IMPImageOrientation = UIImageOrientation
    
#else
    import Cocoa
    
    public enum IMPImageOrientation : Int {
        case up             // 0,  default orientation
        case down           // 1, -> Up    (0), UIImage, 180 deg rotation
        case left           // 2, -> Right (3), UIImage, 90 deg CCW
        case right          // 3, -> Down  (1), UIImage, 90 deg CW
        case upMirrored     // 4, -> Right (3), UIImage, as above but image mirrored along other axis. horizontal flip
        case downMirrored   // 5, -> Right (3), UIImage, horizontal flip
        case leftMirrored   // 6, -> Right (3), UIImage, vertical flip
        case rightMirrored  // 7, -> Right (3), UIImage, vertical flip
    }
    
    public typealias UIImageOrientation = IMPImageOrientation
    
#endif

import CoreImage
import simd
import Metal
import MetalKit
import AVFoundation
import ImageIO


public extension IMPImageOrientation {
    //
    // Exif codes, F is example
    //
    // 1        2       3      4         5            6           7          8
    //
    // 888888  888888      88  88      8888888888  88                  88  8888888888
    // 88          88      88  88      88  88      88  88          88  88      88  88
    // 8888      8888    8888  8888    88          8888888888  8888888888          88
    // 88          88      88  88
    // 88          88  888888  888888
    
    //                                  EXIF orientation
    //    case Up             // 0, < - (1), default orientation
    //    case Down           // 1, < - (3), UIImage, 180 deg rotation
    //    case Left           // 2, < - (8), UIImage, 90 deg CCW
    //    case Right          // 3, < - (6), UIImage, 90 deg CW
    //    case UpMirrored     // 4, < - (2), UIImage, as above but image mirrored along other axis. horizontal flip
    //    case DownMirrored   // 5, < - (4), UIImage, horizontal flip
    //    case LeftMirrored   // 6, < - (5), UIImage, vertical flip
    //    case RightMirrored  // 7, < - (7), UIImage, vertical flip
    
    public init?(exifValue: IMPImageOrientation.RawValue) {
        switch exifValue {
        case 1:
            self.init(rawValue: IMPImageOrientation.up.rawValue)            // IMPExifOrientationUp
        case 2:
            self.init(rawValue: IMPImageOrientation.upMirrored.rawValue)    // IMPExifOrientationHorizontalFlipped
        case 3:
            self.init(rawValue: IMPImageOrientation.down.rawValue)          // IMPExifOrientationLeft180
        case 4:
            self.init(rawValue: IMPImageOrientation.downMirrored.rawValue)  // IMPExifOrientationVerticalFlipped
        case 5:
            self.init(rawValue: IMPImageOrientation.leftMirrored.rawValue)  // IMPExifOrientationLeft90VertcalFlipped
        case 6:
            self.init(rawValue: IMPImageOrientation.right.rawValue)         // IMPExifOrientationLeft90
        case 7:
            self.init(rawValue: IMPImageOrientation.rightMirrored.rawValue) // IMPExifOrientationLeft90HorizontalFlipped
        case 8:
            self.init(rawValue: IMPImageOrientation.left.rawValue)          // IMPExifOrientationRight90
        default:
            self.init(rawValue: IMPImageOrientation.up.rawValue)
        }
    }
    
    public init?(exifValue: IMPImageOrientation) {
        self.init(rawValue: Int(exifValue.rawValue))
    }
    
    public var exifValue:Int {
        return Int(IMPExifOrientation(imageOrientation: self)!.rawValue)
    }
}

public extension IMPExifOrientation {
    public init?(imageOrientation: IMPImageOrientation) {
        switch imageOrientation {
        case .up:
            self.init(rawValue: IMPExifOrientation.up.rawValue)
        case .upMirrored:
            self.init(rawValue: IMPExifOrientation.horizontalFlipped.rawValue)
        case .down:
            self.init(rawValue: IMPExifOrientation.left180.rawValue)
        case .downMirrored:
            self.init(rawValue: IMPExifOrientation.verticalFlipped.rawValue)
        case .leftMirrored:
            self.init(rawValue: IMPExifOrientation.left90VertcalFlipped.rawValue)
        case .right:
            self.init(rawValue: IMPExifOrientation.left90.rawValue)
        case .rightMirrored:
            self.init(rawValue: IMPExifOrientation.left90HorizontalFlipped.rawValue)
        case .left:
            self.init(rawValue: IMPExifOrientation.right90.rawValue)
        }
    }
    
    public var imageOrientation:IMPImageOrientation {
        return IMPImageOrientation(exifValue: Int(self.rawValue))!
    }
}

public enum IMPImageStorageMode {
    case shared
    case local
}


/// Image provider base protocol
public protocol IMPImageProvider: IMPTextureProvider, IMPContextProvider{
    
    var mutex:IMPSemaphore {get}
    
    typealias ObserverType = (_ :IMPImageProvider) -> Void
    
    var image:CIImage?{ get set }
    var size:NSSize? {get}
    var colorSpace:CGColorSpace {get set}
    var orientation:IMPImageOrientation {get set}
    var videoCache:IMPVideoTextureCache {get}
    var storageMode:IMPImageStorageMode {get}
    init(context:IMPContext, storageMode:IMPImageStorageMode?)
    func addObserver(optionsChanged observer: @escaping ObserverType)
    func removeObserver(optionsChanged observer: @escaping ObserverType)
    func removeObservers()
}

// MARK: - construcutors
public extension IMPImageProvider {
    
    public init(context: IMPContext,
                url: URL,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        #if os(iOS)
            self.init(context:context, storageMode: storageMode)
            self.image = prepareImage(image: CIImage(contentsOf: url, options: [kCIImageColorSpace: colorSpace]),
                                      maxSize: maxSize, orientation: orientation)
        #elseif os(OSX)
            let image = NSImage(byReferencing: url)
            self.init(context: context,
                      image: image,
                      storageMode:storageMode,
                      maxSize:maxSize,
                      orientation:orientation)
        #endif
    }
    
    public init(context: IMPContext,
                path: String,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        self.init(context: context, url: URL(fileURLWithPath:path),
                  storageMode:storageMode,
                  maxSize:maxSize,
                  orientation:orientation)
    }
    
    public init(context: IMPContext,
                provider: IMPImageProvider,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        self.init(context:context, storageMode: storageMode)
        self.image = prepareImage(image: provider.image?.copy() as? CIImage,
                                  maxSize: maxSize, orientation: orientation)
    }
    
    public init(context: IMPContext,
                image: CIImage,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        self.init(context:context, storageMode: storageMode)
        self.image = prepareImage(image: image.copy() as? CIImage,
                                  maxSize: maxSize, orientation: orientation)
    }
    
    
    public init(context: IMPContext,
                image: NSImage,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        self.init(context:context, storageMode: storageMode)
        #if os(OSX)
            guard let data = image.tiffRepresentation else {
                return
            }
            let ciimage = CIImage(data: data, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
            let imageOrientation = IMPImageOrientation.up
        #else
            let ciimage = CIImage(cgImage: image.cgImage!, options: [kCIImageColorSpace: colorSpace])
            let imageOrientation = image.imageOrientation
        #endif
        
        self.image = prepareImage(image: ciimage,
                                  maxSize: maxSize, orientation: orientation ?? imageOrientation)
    }
    
    public init(context: IMPContext,
                data: Data,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){

        self.init(context:context, storageMode: storageMode)

        let ciimage = CIImage(data: data, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
        let imageOrientation = IMPImageOrientation.up
        
        self.image = prepareImage(image: ciimage,
                                  maxSize: maxSize, orientation: orientation ?? imageOrientation)
    }
    
    public init(context: IMPContext,
                image: CGImage,
                storageMode:IMPImageStorageMode? = nil,
                maxSize: CGFloat = 0,
                orientation:IMPImageOrientation? = nil){
        self.init(context:context, storageMode: storageMode)
        self.image = prepareImage(image: CIImage(cgImage: image, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace])),
                                  maxSize: maxSize, orientation: orientation)
    }
    
    public init(context: IMPContext, image: CMSampleBuffer, storageMode:IMPImageStorageMode? = .local, maxSize: CGFloat = 0){
        self.init(context:context, storageMode: storageMode)
        self.update(image)
    }
    
    public init(context: IMPContext, image: CVImageBuffer, storageMode:IMPImageStorageMode? = .local, maxSize: CGFloat = 0){
        self.init(context:context, storageMode: storageMode)
        self.update(image)
    }
    
    public init(context: IMPContext, texture: MTLTexture){
        var mode = IMPImageStorageMode.shared
        if texture.storageMode == .private {
            mode = .local
        }
        self.init(context:context, storageMode:mode)
        self.texture = texture
    }
    
    
    public mutating func update(_ inputImage:CIImage){
        image = inputImage
    }
    
    public mutating func update(_ inputImage:CGImage){
        image = CIImage(cgImage: inputImage)
    }
    
    public mutating func update(_ inputImage:NSImage){
        #if os(OSX)
            guard let data = inputImage.tiffRepresentation else { return }
            image = CIImage(data: data, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
        #else
            image = CIImage(image: inputImage)
        #endif
    }
    
    public mutating func update(_ buffer:CMSampleBuffer){
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            update(pixelBuffer)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        }
    }
    
    public mutating func update(_ buffer: CVImageBuffer) {
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        var textureRef:CVMetalTexture?
        
        guard let vcache = videoCache.videoTextureCache else {
            fatalError("IMPImageProvider error: couldn't create video cache... )")
        }
        
        let error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                              vcache,
                                                              buffer, nil,
                                                              .bgra8Unorm,
                                                              width,
                                                              height,
                                                              0,
                                                              &textureRef)
        
        if error != kCVReturnSuccess {
            fatalError("IMPImageProvider error: couldn't create texture from pixelBuffer: \(error)")
        }
        
        if let ref = textureRef,
            let texture = CVMetalTextureGetTexture(ref) {
            self.texture = texture // texture.makeTextureView(pixelFormat: IMProcessing.colors.pixelFormat)
        }
        else {
            fatalError("IMPImageProvider error: couldn't create texture from pixelBuffer: \(error)")
        }
    }
    
    internal mutating func prepareImage(image originImage: CIImage?, maxSize: CGFloat, orientation:IMPImageOrientation? = nil)  -> CIImage? {
        
        guard let image = originImage else { return originImage }
        
        let size       = image.extent
        let imagesize  = max(size.width, size.height)
        let scale      = maxSize > 0 ? min(maxSize/imagesize,1) : 1
        
        var transform  = scale == 1 ? CGAffineTransform.identity : CGAffineTransform(scaleX: scale, y: scale)
        
        var reflectHorisontalMode = false
        var reflectVerticalMode = false
        var angle:CGFloat = 0
        
        
        if let orientation = orientation {
            
            self.orientation = orientation
            
            //
            // CIImage render to verticaly mirrored texture
            //
            
            switch orientation {
                
            case .up:
                angle = CGFloat.pi
                reflectHorisontalMode = true // 0
                
            case .upMirrored:
                reflectHorisontalMode = true
                reflectVerticalMode   = true // 4
                
            case .down:
                reflectHorisontalMode = true // 1
                
            case .downMirrored: break        // 5
                
            case .left:
                angle = -CGFloat.pi/2
                reflectHorisontalMode = true // 2
                
            case .leftMirrored:
                angle = -CGFloat.pi/2
                reflectVerticalMode   = true
                reflectHorisontalMode = true // 6
                
            case .right:
                angle = CGFloat.pi/2
                reflectHorisontalMode = true // 3
                
            case .rightMirrored:
                angle = CGFloat.pi/2
                reflectVerticalMode   = true
                reflectHorisontalMode = true // 7
            }
        }
        
        if reflectHorisontalMode {
            transform = transform.scaledBy(x: -1, y: 1).translatedBy(x: size.width, y: 0)
        }
        
        if reflectVerticalMode {
            transform = transform.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: size.height)
        }
        
        //
        // fix orientation
        //
        transform = transform.rotated(by: CGFloat(angle))
        
        return image.transformed(by: transform)
    }
}


public extension IMPImageProvider {
    
    public func read(commandBuffer:MTLCommandBuffer?=nil) ->  (buffer:MTLBuffer,bytesPerRow:Int,imageBytes:Int)? {
        
        if let size = self.size,
            let texture = texture?.pixelFormat != .rgba8Uint ?
                texture?.makeTextureView(pixelFormat: .rgba8Uint) :
            texture
        {
            
            let width       = Int(size.width)
            let height      = Int(size.height)
            
            let bytesPerRow   = width * 4
            let imageBytes = height * bytesPerRow
            
            let buffer = self.context.device.makeBuffer(length: imageBytes, options: [])
            
            
            func readblit(commandBuffer:MTLCommandBuffer){
                let blit = commandBuffer.makeBlitCommandEncoder()
                
                blit?.copy(from:          texture,
                           sourceSlice:  0,
                           sourceLevel:  0,
                           sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                           sourceSize:   texture.size,
                           to:           buffer!,
                           destinationOffset: 0,
                           destinationBytesPerRow: bytesPerRow,
                           destinationBytesPerImage: imageBytes)
                
                blit?.endEncoding()
            }
            
            
            if let command = commandBuffer {
                readblit(commandBuffer: command)
            }
            else {
                context.execute(wait: true) { (commandBuffer) in
                    
                    readblit(commandBuffer: commandBuffer)
                    
                    //                let blit = commandBuffer.makeBlitCommandEncoder()
                    //
                    //                blit.copy(from:          texture,
                    //                          sourceSlice:  0,
                    //                          sourceLevel:  0,
                    //                          sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                    //                          sourceSize:   texture.size,
                    //                          to:           buffer,
                    //                          destinationOffset: 0,
                    //                          destinationBytesPerRow: bytesPerRow,
                    //                          destinationBytesPerImage: imageBytes)
                    //                
                    //                blit.endEncoding()
                }
            }
            return (buffer,bytesPerRow,imageBytes) as? (buffer: MTLBuffer, bytesPerRow: Int, imageBytes: Int) //as! (buffer: MTLBuffer, bytesPerRow: Int, imageBytes: Int)
        }
        
        
        //        if let size = self.size,
        //            let texture = texture?.pixelFormat != .rgba8Uint ?
        //                texture?.makeTextureView(pixelFormat: .rgba8Uint) :
        //                texture
        //        {
        //            
        //            let width       = Int(size.width)
        //            let height      = Int(size.height)
        //            
        //            bytesPerRow   = width * 4
        //            let newSize = height * bytesPerRow
        //            
        //            if bytes == nil {
        //                bytes = UnsafeMutablePointer<UInt8>.allocate(capacity:newSize)
        //            }
        //            else if imageByteSize != newSize {
        //                if imageByteSize > 0 {
        //                    bytes?.deallocate(capacity: imageByteSize)
        //                }
        //                bytes = UnsafeMutablePointer<UInt8>.allocate(capacity:newSize)
        //            }
        //
        //            if bytes == nil {
        //                context.resume()
        //                return  nil
        //            }
        //            
        //            imageByteSize = newSize
        //            
        //            #if os(OSX)
        //                guard let command = context.commandBuffer else { return nil }
        //                let blit = command.makeBlitCommandEncoder()
        //                blit.synchronize(resource: texture)
        //                blit.endEncoding()
        //                command.commit()
        //                command.waitUntilCompleted()
        //            #endif
        //                        
        //            texture.getBytes(bytes!,
        //                             bytesPerRow: bytesPerRow,
        //                             from: MTLRegionMake2D(0, 0, texture.width, texture.height),
        //                             mipmapLevel: 0)
        //            
        //            context.resume()
        //            return bytes
        //        }
        
        //context.resume()
        return nil
    }
}


// MARK: - render
public extension IMPImageProvider {
    
    public func render(from image:CIImage?, 
                       to texture: inout MTLTexture?,
                       flipVertical:Bool = false,
                       complete:((_ texture:MTLTexture?, _ command:MTLCommandBuffer?)->Void)?=nil) {
        
        var texture = texture
        
        context.execute(.sync, wait: true) { (commandBuffer) in
            
            guard  var image = image else {
                complete?(nil,nil)            
                return             
            }
            
            let transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height)
            image = !flipVertical ? image : image.transformed(by: transform)
            
            texture = self.checkTexture(texture: texture)
            
            if let t = texture {
                self.context.coreImage?.render(image,
                                               to: t,
                                               commandBuffer: commandBuffer,
                                               bounds: image.extent,
                                               colorSpace: self.colorSpace)
                complete?(t,commandBuffer)
            }
            else {
                complete?(nil,nil)            
            }
        }
    }
    
    
    public func render(to texture: inout MTLTexture?,
                       flipVertical:Bool = false,
                       complete:((_ texture:MTLTexture?, _ command:MTLCommandBuffer?)->Void)?=nil) {
        
        guard  var image:CIImage = self.image  else {
            complete?(nil,nil)            
            return             
        }
        
        texture = checkTexture(texture: texture)
        
        if let t = texture {
            context.execute(.sync, wait: true) { (commandBuffer) in
                
                let transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height)
                image = !flipVertical ? image : image.transformed(by: transform)
                
                self.context.coreImage?.render(image,
                                               to: t,
                                               commandBuffer: commandBuffer,
                                               bounds: image.extent,
                                               colorSpace: self.colorSpace)
                complete?(t,commandBuffer)
            }
        }
        else {
            complete?(nil,nil)            
        }
    }
    
    public func asyncRender(to texture: MTLTexture,
                            execute:((_ command:MTLCommandBuffer?)->Void)?=nil,
                            complete:((_ command:MTLCommandBuffer?)->Void)?=nil) {
        
        context.runOperation(.async) { 
            
            if let commandBuffer = self.context.commandBuffer {
                
                commandBuffer.addCompletedHandler{ commandBuffer in            
                    complete?(commandBuffer)                
                    return
                }                
                
                if let txt = self.texture {
                    
                    let blit = commandBuffer.makeBlitCommandEncoder()
                    
                    blit?.copy(
                        from: txt,
                        sourceSlice: 0,
                        sourceLevel: 0,
                        sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                        sourceSize: txt.size,
                        to: texture,
                        destinationSlice: 0,
                        destinationLevel: 0,
                        destinationOrigin: MTLOrigin(x:0,y:0,z:0))
                    
                    blit?.endEncoding()                    
                }      
                
                execute?(commandBuffer) 
                
                commandBuffer.commit()                
                commandBuffer.waitUntilCompleted()                
            }
        }
    }
    
    public func asyncRender(to view: MTKView,
                            execute:((_ command:MTLCommandBuffer?)->Void)?=nil,
                            complete:((_ command:MTLCommandBuffer?)->Void)?=nil) {
        
        context.runOperation(.async) { 
            if let txt = self.texture {
                
                DispatchQueue.main.async {
                    view.drawableSize = txt.cgsize                    
                }
                
                if let currentDrawable = view.currentDrawable, let commandBuffer = self.context.commandBuffer {
                    
                    let texture = currentDrawable.texture
                    
                    commandBuffer.addCompletedHandler{ commandBuffer in            
                        complete?(commandBuffer)                
                        return
                    }                
                    
                    
                    let blit = commandBuffer.makeBlitCommandEncoder()
                    
                    blit?.copy(
                        from: txt,
                        sourceSlice: 0,
                        sourceLevel: 0,
                        sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                        sourceSize: txt.size,
                        to: texture,
                        destinationSlice: 0,
                        destinationLevel: 0,
                        destinationOrigin: MTLOrigin(x:0,y:0,z:0))
                    
                    blit?.endEncoding()                    
                    
                    execute?(commandBuffer) 
                    
                    commandBuffer.present(currentDrawable)
                    commandBuffer.commit()            
                    
                    commandBuffer.waitUntilCompleted()   
                }
                else {
                    complete?(nil)
                }
            }
            else {
                complete?(nil)                
                
            }
        }
    }
    
    
    public func render(to texture: inout MTLTexture?,
                       with commandBuffer: MTLCommandBuffer,
                       flipVertical:Bool = false,
                       comlete:((_ texture:MTLTexture?, _ command:MTLCommandBuffer?)->Void)? = nil) {
        
        guard  var image = self.image else {
            comlete?(nil,nil)
            return             
        }
        
        let transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height)
        image = !flipVertical ? image : image.transformed(by: transform)
        
        texture = checkTexture(texture: texture)
        
        if let t = texture {
            self.context.coreImage?.render(image,
                                           to: t,
                                           commandBuffer: commandBuffer,
                                           bounds: image.extent,
                                           colorSpace: self.colorSpace)
            comlete?(t,commandBuffer)
        }
        else {
            comlete?(nil,nil)
        }
    }
    
    public func makeCopy() -> MTLTexture? {
        var newTexture:MTLTexture? = nil
        
        context.execute { (commandBuffer) in
            
            if let txt = self.texture {
                
                newTexture = self.context.device.make2DTexture(size: txt.cgsize, pixelFormat: txt.pixelFormat)
                
                let blit = commandBuffer.makeBlitCommandEncoder()
                
                blit?.copy(
                    from: txt,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                    sourceSize: txt.size,
                    to: newTexture!,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x:0,y:0,z:0))
                
                blit?.endEncoding()
            }
        }
        
        return newTexture
    }
    
    public func makeTextureCopyAsync(copy: @escaping (_ texture:MTLTexture?)->Void){
        
        context.runOperation(.async) {
            
            if let txt = self.texture, let commandBuffer = self.context.commandBuffer {
                
                let newTexture = self.context.device.make2DTexture(size: txt.cgsize, pixelFormat: txt.pixelFormat)
                
                let blit = commandBuffer.makeBlitCommandEncoder()
                
                blit?.copy(
                    from: txt,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                    sourceSize: txt.size,
                    to: newTexture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x:0,y:0,z:0))
                
                blit?.endEncoding()  
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                
                copy(newTexture)
            }
            else {
                copy(nil)
            }
        }                 
    }
    
    
    private func checkTexture(texture:MTLTexture?) -> MTLTexture? {
        
        guard  let image = image else {  return nil }
        
        let width = Int(image.extent.size.width)
        let height = Int(image.extent.size.height)
        
        // if texture?.width != width  || texture?.height != height
        // {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: IMProcessing.colors.pixelFormat,
            width: width, height: height, mipmapped: false)
        
        
        if storageMode == .shared {
            #if os(iOS)
                descriptor.storageMode = .shared
                descriptor.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
            #elseif os(OSX)
                descriptor.storageMode = .managed
                descriptor.usage = [.shaderRead, .shaderWrite, .pixelFormatView, .renderTarget]
            #endif
        }
        else {
            descriptor.storageMode = .private
            descriptor.usage = [.shaderRead, .shaderWrite,.pixelFormatView,.renderTarget]
        }
        
        if texture != nil {
            //texture?.setPurgeableState(.volatile)
        }
        
        return self.context.device.makeTexture(descriptor: descriptor)
        
    }
    
    public func scaledImage(with scale:CGFloat, reflect:Bool = false) -> CIImage? {
        guard let image = image else { return nil }
        var t = CGAffineTransform.identity
        t = t.scaledBy(x: scale, y: scale)
        if reflect {
            t = t.scaledBy(x: 1, y: -1)
        }        
        t = t.translatedBy(x: 0, y: image.extent.size.height*scale)
        return image.transformed(by: t)        
    }
    
    public func cgiImage(scale:CGFloat, reflect:Bool = false) -> CGImage? {
        guard let image = scaledImage(with: scale, reflect:reflect) else { return nil }
        return context.coreImage?.createCGImage(image, from: image.extent,
                                                format: CIFormat.ARGB8,
                                                colorSpace: colorSpace,
                                                deferred:true)                    
    }
    
    public var cgiImage:CGImage? {
        get {
            return cgiImage(scale:1)
        }
        set {
            if let im = newValue {
                image = CIImage(cgImage: im, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
            }
        }
    }
    
    #if os(iOS)
    public var nsImage:NSImage? {
    get{
    guard (image != nil) else { return nil}
    return NSImage(cgImage: cgiImage!)
    }
    set {
    cgiImage = newValue?.cgImage
    }
    }
    #else
    public func nsImage(scale:CGFloat, reflect:Bool = false) -> NSImage? {
        if let cgi =  cgiImage(scale: scale, reflect: reflect){
            return NSImage(cgImage: cgi, size: NSZeroSize)
        }
        return nil
    }
    
    public var nsImage:NSImage? {
        get {
            return nsImage(scale:1)
        }
        set{
            guard let data = newValue?.tiffRepresentation else { return }
            image = CIImage(data: data, options: convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
        }
    }
    #endif
}



#if os(OSX)
    
    public typealias IMPImageFileType = NSBitmapImageRep.FileType
    
    public extension NSImage {
        
        @discardableResult public func representation(using type: IMPImageFileType, compression factor:Float? = nil) -> Data? {
            
            guard let tiffRepresentation = tiffRepresentation(using: .none, factor: factor ?? 1.0), 
                let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) 
                else { return nil }
            
            var properties:[NSBitmapImageRep.PropertyKey : Any] = [:]
            
            if type == .jpeg {
                properties = [NSBitmapImageRep.PropertyKey.compressionFactor: factor ?? 1.0]
            }
            
            return bitmapImage.representation(using: type, properties: properties)            
        }
        
        public convenience init?(ciimage:CIImage?){
            
            guard var image = ciimage else {
                return nil
            }
            
            //
            // convert back to MTL texture coordinates system
            //
            let transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.height)
            image = image.transformed(by: transform)
            
            self.init(size: image.extent.size)
            let rep = NSCIImageRep(ciImage: image)
            addRepresentation(rep)
        }        
    }
    
    // MARK: - export to files
    public extension IMPImageProvider{
        
        
        /// Image provider representaion as Data?
        ///
        /// - Parameters:
        ///   - type: representation type: `IMPImageFileType`
        ///   - factor: compression factor (.JPEG only)
        /// - Returns: representation Data?
        public func representation(using type: IMPImageFileType, compression factor:Float? = nil, reflect:Bool = false) -> Data?{
            
            var properties:[CIImageRepresentationOption : Any] = [:]
            if type == .jpeg {
                properties = [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): factor ?? 1.0]
            }
            
            let csp = self.colorSpace
            
            if let image = self.image { 
                
                var t = CGAffineTransform.identity
                
                if reflect {
                    t = t.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height)
                }
                
                switch type {
                case .jpeg:
                    return context.coreImage?.jpegRepresentation(of: image.transformed(by: t),
                                                                 colorSpace: csp,
                                                                 options: properties)
                case .tiff:
                    return context.coreImage?.tiffRepresentation(of: image.transformed(by: t),
                                                                 format: CIFormat.RGBAf,
                                                                 colorSpace: csp, options:properties)
                case .png:
                    if #available(OSX 10.13, *) {
                        return context.coreImage?.pngRepresentation(of: image.transformed(by: t),
                                                                    format: CIFormat.RGBA16,
                                                                    colorSpace: csp,
                                                                    options: properties)
                    } else {
                        nsImage(scale: 1, reflect: reflect)?.representation(using: type, compression: factor)
                    }
                default:
                    nsImage(scale: 1, reflect: reflect)?.representation(using: type, compression: factor)
                }
            }
            return nil
        }
        
        
        /// Write image to URL
        ///
        /// - Parameters:
        ///   - url: url
        ///   - type: image type
        ///   - factor: compression factor (.JPEG only)
        /// - Throws: `Error`
        public func write(to url: URL, using type: IMPImageFileType, compression factor:Float? = nil, reflect:Bool = false) throws {
            try representation(using: type, compression: factor, reflect:reflect)?.write(to: url, options: .atomic)
        }
        
        public func write(to path: String, using type: IMPImageFileType, compression factor:Float? = nil, reflect:Bool = false) throws {
            try representation(using: type, compression: factor, reflect:reflect)?.write(to: URL(fileURLWithPath: path), options: .atomic)
        }        
    }
    
#endif


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCIImageOptionDictionary(_ input: [String: Any]?) -> [CIImageOption: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (CIImageOption(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCIImageOption(_ input: CIImageOption) -> String {
	return input.rawValue
}
