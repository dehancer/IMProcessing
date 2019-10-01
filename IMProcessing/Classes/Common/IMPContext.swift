//
//  IMPContext.swift
//  IMProcessing
//
//  Created by denis svinarchuk on 15.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
import OpenGL.GL
#endif

import Metal

public func IMPPeekFunc<A, R>(_ f: @escaping (A) -> R) -> (fp: Int, ctx: Int) {
    typealias IntInt = (Int, Int)
    let (_, lo) = unsafeBitCast(f, to: IntInt.self)
    //let lo = unsafeBitCast(f, to: IntInt.self)
    let offset = MemoryLayout<Int>.size == 8 ? 16 : 12
    let ptr = UnsafePointer<Int>(bitPattern: lo + offset)!
    return (ptr.pointee, ptr.successor().pointee)
}

public func IMPPeekFunc<A>(_ f: (A)) -> (fp: Int, ctx: Int) {
    typealias IntInt = (Int, Int)
    let (_, lo) = unsafeBitCast(f, to: IntInt.self)
    let offset = MemoryLayout<Int>.size == 8 ? 16 : 12
    let ptr = UnsafePointer<Int>(bitPattern: lo + offset)!
    return (ptr.pointee, ptr.successor().pointee)
}

public func === <A, R>(lhs: @escaping (A) -> R, rhs: @escaping (A) -> R) -> Bool {
    let (tl, tr) = (IMPPeekFunc(lhs), IMPPeekFunc(rhs))
    return tl.0 == tr.0 && tl.1 == tr.1
}

public func IMPClosuresEqual<A>(_ lhs: (A), _ rhs: (A)) -> Bool {
    return  unsafeBitCast(lhs, to: AnyObject.self) === unsafeBitCast(rhs, to: AnyObject.self)
}

public struct IMPObserverHash<T>:Hashable {
    
    public static func == (lhs: IMPObserverHash<T>, rhs: IMPObserverHash<T>) -> Bool {
        return lhs.key == rhs.key
    }
    
    public let key:String
    public let observer:T     
    public var hashValue: Int {
        return key.hashValue
    }   
    
    public static func observerKey<T>(_ f: T) -> String {
        let addr = IMPPeekFunc(f)
        return "\(addr.fp):\(addr.ctx)"
        //return "IMPObserverHash:observer:\(addr.fp)"
    }  
    
    public init(key:String, observer:T){
        self.key = key
        self.observer = observer
    }
    
    @discardableResult public static func unsafeRemoveObserver<T>(from list: inout [IMPObserverHash<T>], _ observer:T, key aKey:String? = nil) -> String {
        let key = aKey ?? IMPObserverHash<T>.observerKey(observer)
        if let index = list.index(where: { return $0.key == key }) {
            list.remove(at: index)
        }                
        return key
    }    
    
    @discardableResult public static func unsafeAddObserver<T>(to list:inout [IMPObserverHash<T>], _ observer:T, key aKey:String? = nil) -> String{
        let key = unsafeRemoveObserver(from: &list, observer, key: aKey)
        list.append(IMPObserverHash<T>(key:key, observer:observer))
        return key
    }
}

public struct IMPSemaphore {
    private let s = DispatchSemaphore(value: 1)
    public init() {}
    @discardableResult public func sync<R>(execute: () throws -> R) rethrows -> R {
        _ = s.wait(timeout: DispatchTime.distantFuture)
        defer { s.signal() }
        return try execute()
    }
}

///
///  @brief Context provider protocol.
///  All filter classes should conform to the protocol to get access current filter context.
///
public protocol IMPContextProvider: class {
    var context:IMPContext {get}
}

public extension String{
    static func uniqString() -> String{
        return CFUUIDCreateString(nil, CFUUIDCreate(nil)) as String
    }
}


///
/// The IMProcessing framework supports GPU-accelerated advanced data-parallel computation workloads.
/// IMPContext instance is created to connect curren GPU device and resources are allocated in order to
/// do computation.
///
/// IMPContext is a container bring together GPU-device, current command queue and default kernel functions library
/// which export functions to the context.
///
open class IMPContext {
    
    public enum OperationType {
        case sync
        case async
    }
    
    /// Context execution closure
    public typealias Execution = ((_ commandBuffer:MTLCommandBuffer) -> Void)
    
    /// Current device is used in the current context
    open var device:MTLDevice {
        return IMPDevice.shared.device
    }
    
    open var coreImage:CIContext? {
        if #available(iOS 9.0, *) {
            return _ciContext
        } else {
            return nil
        }
    }
    
    public let uid = String.uniqString()
    
    /// Current command queue uses the current device
    open var commandQueue:MTLCommandQueue?  {
        return IMPDevice.shared.commandQueue
    }
   
    
    /// Default library associated with current context
    public var defaultLibrary:MTLLibrary {
        return IMPDevice.shared.defaultLibrary
    }
    
    /// How context execution is processed
    public let isLazy:Bool
    
    /// check whether the MTL device is supported
    public static var supportsSystemDevice:Bool{
        get{
            let device = MTLCreateSystemDefaultDevice()
            if device == nil {
                return false
            }
            return true
        }
    }
    
    open func makeLibrary(source:String) throws -> MTLLibrary {
        let options = MTLCompileOptions()
        options.fastMathEnabled = true
        return try device.makeLibrary(source: source, options: options)
    }
    
    fileprivate let semaphore = DispatchSemaphore(value: 1)
    
    open func wait() {
        semaphore.wait()
    }
    open func resume(){
        semaphore.signal()
    }
    
    public let dispatchQueue = DispatchQueue (label: "ccom.improcessing.context", qos : .utility)
    private var dispatchQueueKey:DispatchSpecificKey<Int> =  DispatchSpecificKey<Int>()
    private  let queueKey: Int = 1837264
    
    ///  Initialize current context
    ///
    ///  - parameter lazy: true if you need to process without waiting finishing computation in the context.
    ///
    ///  - returns: context instanc
    ///
    required public init(device: MTLDevice? = nil,  lazy:Bool = false) {        
        dispatchQueue.setSpecific(key: dispatchQueueKey, value: queueKey)        
        isLazy = lazy        
    }
        
    @available(iOS 9.0, *)
    lazy var _ciContext:CIContext = CIContext(mtlDevice: self.device)
    
    open lazy var supportsGPUv2:Bool = {
        #if os(iOS)
        return self.device.supportsFeatureSet(.iOS_GPUFamily2_v1)
        #else
        return true
        #endif
    }()
    
    var commandBuffer:MTLCommandBuffer?  {
        return self.commandQueue?.makeCommandBuffer()
    }
    
    public var maxThreads:MTLSize {
        return device.maxThreadsPerThreadgroup
    }
    
    
    ///  The main idea context execution: all filters should put commands in context queue within the one execution.
    ///
    ///  - parameter closure: execution context
    ///
    public final func execute(_ sync:OperationType = .sync,
                              wait:     Bool = false,
                              complete: (() -> Void)? = nil,
                              fail:     (() -> Void)? = nil,
                              action:   @escaping Execution) {
        
        //unowned let this = self
        
        runOperation(sync) { [weak self] in
            
            #if DEBUG
            //this.commandQueue?.insertDebugCaptureBoundary()
            #endif
            
            if let commandBuffer = self?.commandBuffer, let this = self {
                
                action(commandBuffer)
                
                commandBuffer.commit()
                
                if !this.isLazy || wait {
                    commandBuffer.waitUntilCompleted()
                }
                
                complete?()
            }
            else {
                fail?()
            }
            
            #if DEBUG
            //this.commandQueue?.insertDebugCaptureBoundary()
            #endif
            
        }
    }
    
    @discardableResult public final func runOperation(_ sync:OperationType = .async, _ execute:@escaping () -> ()) -> DispatchWorkItem? {
        
        if sync == .sync {
            if (DispatchQueue.getSpecific(key:dispatchQueueKey) == queueKey) {
                execute()
                return nil
            }
            else {
                let block = DispatchWorkItem { 
                    execute()
                }
                dispatchQueue.sync(execute: block)
                
                return block
            }
        }
        else {
            let block = DispatchWorkItem(flags: [.barrier]) {
                execute()
            }
            dispatchQueue.async(execute: block)
            return block
        }
    }
    
    public func makeCopy(texture:MTLTexture) -> MTLTexture? {
        var newTexture:MTLTexture? = nil
        
        execute { [unowned self] (commandBuffer) in
            
            newTexture = self.device.make2DTexture(size: texture.cgsize, pixelFormat: texture.pixelFormat)
            
            let blit = commandBuffer.makeBlitCommandEncoder()
            
            blit?.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                sourceSize: texture.size,
                to: newTexture!,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x:0,y:0,z:0))
            
            blit?.endEncoding()
        }
        
        return newTexture
    }
    
    public func makeCopy(texture:MTLTexture, to:IMPContext) -> MTLTexture? {
        
        if to === self {
            return makeCopy(texture: texture)
        }
        
        var newTexture:MTLTexture? = nil
        
        to.execute { [unowned to] (commandBuffer) in
            
            newTexture = to.device.make2DTexture(size: texture.size, pixelFormat: texture.pixelFormat)
            
            let blit = commandBuffer.makeBlitCommandEncoder()
            
            blit?.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x:0,y:0,z:0),
                sourceSize: texture.size,
                to: newTexture!,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x:0,y:0,z:0))
            
            blit?.endEncoding()
        }
        
        return newTexture
    }
    
    
    public var textureCache:IMPTextureCache {
        return _textureCache
    }
    
    ///  the maximum supported devices texture size.
    public static var maximumTextureSize:Int{
        
        set(newMaximumTextureSize){
            IMPContext.sharedContainer.currentMaximumTextureSize = 0
            var size = IMPContext.sharedContainer.currentMaximumTextureSize
            if newMaximumTextureSize <= size {
                size = newMaximumTextureSize
            }
            IMPContext.sharedContainer.currentMaximumTextureSize = size
        }
        
        get {
            return IMPContext.sharedContainer.currentMaximumTextureSize
        }
    }
    
    ///  Get texture size alligned to maximum size which is suported by the current device
    ///
    ///  - parameter inputSize: real size of texture
    ///  - parameter maxSize:   size of a texture which can be placed to the context
    ///
    ///  - returns: maximum size
    ///
    public static func sizeAdjustTo(size inputSize:CGSize, maxSize:Float = Float(IMPContext.maximumTextureSize)) -> CGSize
    {
        if (inputSize.width < CGFloat(maxSize)) && (inputSize.height < CGFloat(maxSize))  {
            return inputSize
        }
        
        var adjustedSize = inputSize
        
        if inputSize.width > inputSize.height {
            adjustedSize = CGSize(width: CGFloat(maxSize), height: ( CGFloat(maxSize) / inputSize.width) * inputSize.height)
        }
        else{
            adjustedSize = CGSize(width: ( CGFloat(maxSize) / inputSize.height) * inputSize.width, height:CGFloat(maxSize))
        }
        
        return adjustedSize;
    }
    
    private lazy var _textureCache:IMPTextureCache = { return IMPTextureCache(context: self) }()
    
    // Singleton Class
    fileprivate class sharedContainerType: NSObject {
        
        fileprivate static var maxTextureSize:GLint = 0
        var currentMaximumTextureSize:Int
        
        static let sharedInstance:sharedContainerType = {
            let instance = sharedContainerType ()
            return instance
        } ()
        
        override init() {
            #if os(iOS)
            let glContext =  EAGLContext(api: .openGLES2)
            EAGLContext.setCurrent(glContext)
            glGetIntegerv(GLenum(GL_MAX_TEXTURE_SIZE), &sharedContainerType.maxTextureSize)
            currentMaximumTextureSize = Int(sharedContainerType.maxTextureSize)
            #else
            var pixelAttributes:[NSOpenGLPixelFormatAttribute] = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFAAccelerated), 0]
            let pixelFormat = NSOpenGLPixelFormat(attributes: &pixelAttributes)
            let context = NSOpenGLContext(format: pixelFormat!, share: nil)
            context?.makeCurrentContext()
            glGetIntegerv(GLenum(GL_MAX_TEXTURE_SIZE), &sharedContainerType.maxTextureSize)
            currentMaximumTextureSize = Int(sharedContainerType.maxTextureSize)
            #endif
        }
    }
    
    fileprivate static var sharedContainer = sharedContainerType()
}

public extension IMPContext {
    
    public func makeBuffer<T>(from value:T, options: MTLResourceOptions = []) -> MTLBuffer {
        var value = value
        var length = MemoryLayout.size(ofValue: value)
        if value is Array<Any> {
            if let v = value as? Array<Any> {
                length *= v.count
            }
        }
        return device.makeBuffer(bytes: &value, length: length, options: options)!
    }
    
    public func make2DTexture(size: MTLSize,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        return device.make2DTexture(size: size, pixelFormat: pixelFormat, mode: mode)
    }
    
    public func make2DTexture(size: NSSize,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        return device.make2DTexture(size: size, pixelFormat: pixelFormat, mode: mode)
    }
    
    public func make2DTexture(width:Int, height:Int,
                              pixelFormat:MTLPixelFormat = IMProcessing.colors.pixelFormat,
                              mode:IMPImageStorageMode = .shared) -> MTLTexture {
        return device.make2DTexture(width:width, height:height, pixelFormat: pixelFormat, mode: mode)
    }
}

precedencegroup Precedence {
    associativity: right
    lowerThan: AdditionPrecedence
}

private func fatalAssignment<T>(_ left: MTLBuffer, _ right: T) {
    fatalError("MTLBuffer: invalid buffer assighment size: \(left.length) from \(MemoryLayout<T>.size)")
}

public extension MTLBuffer{
    public func copy<T>(from value:T) {
        guard length == MemoryLayout<T>.size else { fatalAssignment(self, value); return }
        var value = value
        memcpy(contents(), &value, length)
    }
}
