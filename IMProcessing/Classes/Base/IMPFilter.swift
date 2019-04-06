//
//  IMPFilter.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 12.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
import UIKit
import MetalPerformanceShaders
#else
import Cocoa
#endif

import Metal
import CoreImage

public protocol IMPFilterProtocol:IMPContextProvider, IMPDestinationSizeProvider {
    typealias CompleteHandler = ((_ image:IMPImageProvider)->Void)
    
    var  name:             String            {get    }
    var  source:           IMPImageProvider? {get set}
    var  destination:      IMPImageProvider  {get    }
    var  observersEnabled: Bool              {get set}
    var  enabled:          Bool              {get set}
    var  dirty:            Bool              {get set}
    
    init(context:IMPContext, name: String?)
    
    func configure(complete:CompleteHandler?)
    
    func process<T:IMPFilter>() -> T
}


open class IMPFilter: IMPFilterProtocol, /*IMPDestinationSizeProvider,*/ Equatable {
    
    public var mutex = IMPSemaphore()
    public var observingType:IMPContext.OperationType = .async {
        didSet{
            for c in self.coreImageFilterList {
                c.filter?.observingType = observingType
            }
            //root?.observingType = observingType
        }
    }
    
    public static let filterType = IMPFilter.self
    
    // MARK: - Type aliases
    
    public enum RegisteringError: Error {
        case AlreadyExist
        case NotFound
        case OutOfRangeInsertion
    }
    
    public typealias FailHandler          = (_ error:RegisteringError)->Void
    public typealias CompleteHandler      = (_ image:IMPImageProvider)->Void
    public typealias UpdateHandler        = (_ image:IMPImageProvider) -> Void
    public typealias SourceUpdateHandler  = (_ image:IMPImageProvider?) -> Void
    public typealias FilterHandler        = (_ filter:IMPFilter, _ source:IMPImageProvider?, _ destination:IMPImageProvider) -> Void
    
    // MARK: - public
    
    open var prefersRendering:Bool  {
        return  context.supportsGPUv2
    }
    
    public var name: String {
        return _name!
    }
    
    public lazy var _name: String? = String.uniqString() //self.context.uid
    
    public var context: IMPContext
    
    public var observersEnabled: Bool = true
    
    open var source: IMPImageProvider? = nil {
        willSet{
            source?.removeObserver(optionsChanged: optionChangedObserver)
        }
        didSet{   
            _destination.texture = nil
            executeNewSourceObservers(source: source)
            source?.addObserver(optionsChanged: optionChangedObserver)
        }
    }
    
    private lazy var optionChangedObserver:IMPImageProvider.ObserverType = {
        let handler:IMPImageProvider.ObserverType = { source in
            self.dirty = true                
        } 
        return handler        
    }() 
    
    public var destination: IMPImageProvider {
        guard dirty || (_destination.texture == nil) else {
            return _destination
        }
        return apply(result: _destination, resampleSize: nil)
    }
    
    public var destinationSize: NSSize?
    
    public required init(context:IMPContext, name: String? = nil) {
        self.context = context
        _name = name ?? String(describing: type(of: self)) + ":" + String.uniqString()
        defer {
            configure()
        }
    }
    
    public var enabled: Bool = true {
        didSet{
            dirty = true
            executeEnablingObservers(filter: self)
        }
    }
    
    public var dirty: Bool = true {
        didSet{
            
            if isIgnoringDirty { return }
            
            for c in self.coreImageFilterList {
                c.filter?.dirty = dirty
            }
            
            //root?.resetDirty(dirty)
                        
            //root?.dirty = self.dirty
            
            if dirty {
                if root == nil {
                    executeDirtyObservers(filter: self)
                }
            }
        }
    }
    
    private var isIgnoringDirty: Bool = false {
        didSet{        
            for c in self.coreImageFilterList {
                c.filter?.isIgnoringDirty = isIgnoringDirty
            }
        }
    }
    
    public func ignoringDirty(_ execute: ()->Void) {
        isIgnoringDirty = true
        execute()
        isIgnoringDirty = false
    }
    
//    private func resetDirty(_ dirty:Bool){
//        self.dirty = dirty
//    }
    
    public var chain:[FilterContainer] {
        return coreImageFilterList
    }
    
    @discardableResult public func extendName<T:IMPFilter>(suffix:String) -> T {
        _name = {
            if _name == nil {
                return String.uniqString() + ":" + suffix
            }
            return self._name! + ":" + suffix
        }()
        return self as! T
    }
    
    open func configure(complete:CompleteHandler?=nil) {
        if let c = complete {
            addObserver(destinationUpdated: { (destination) in
                c(destination)
            })
        }
    }
    
    public func flush(){
        source?.image = nil
        _destination.image = nil
        for c in coreImageFilterList {
            if let f = c.filter {
                f.flush()
            }
            else if let f = c.cifilter as? IMPCIFilter{
                f.flush()
            }
        }
    }
    
    @discardableResult public func process<T:IMPFilter>() -> T {
        guard dirty || (_destination.texture == nil) else {
            return  self as! T
        }
        apply(result: _destination, resampleSize: nil)
        return self as! T
    }
    
    public func resample<T:IMPImageProvider>(with resampleSize:NSSize? = nil) -> T {
        guard dirty || (_destination.texture == nil) else {
            return _destination as! T
        }
        return apply(result: _destination, resampleSize: resampleSize) as! T
    }
    
    @discardableResult private func apply(result:IMPImageProvider, resampleSize:NSSize?) -> IMPImageProvider {
        
        guard let source = self.source else {
            executeDestinationObservers(destination: result)
            dirty = false
            return result
        }
        
        guard let size = source.size else {
            executeDestinationObservers(destination: result)
            dirty = false
            return result
        }
        
        var result = result
        
        if fmax(size.width, size.height) <= IMPContext.maximumTextureSize.cgfloat {
            
            if enabled == false {
                result.texture = source.texture
                executeDestinationObservers(destination: result)
                dirty = false
                return result
            }
            
            let destSize = resampleSize ?? destinationSize ?? size
            
            result.texture = self.apply(size:destSize, commandBuffer: nil)
            
            self.executeDestinationObservers(destination: result)
            self.dirty = false
            return result
        }
        
        var scaledImage = source.image
        
        if let newsize = destinationSize ?? source.size,
            let sImage = scaledImage
        {
            let originX = sImage.extent.origin.x
            let originY = sImage.extent.origin.y
            
            let scaleX = newsize.width /  sImage.extent.width
            let scaleY = newsize.height / sImage.extent.height
            let scale = min(scaleX, scaleY)
            
            let transform = CGAffineTransform.identity.translatedBy(x: -originX, y: -originY)
            scaledImage = sImage.transformed(by: transform.scaledBy(x: scale, y: scale))
        }
        
        result.image = scaledImage
        
        if enabled == false {
            executeDestinationObservers(destination: result)
            dirty = false
            return result
        }
        
        //
        // apply CIFilter chains
        //
        for c in coreImageFilterList {
            if let filter = c.cifilter {
                filter.setValue(result.image?.copy(), forKey: kCIInputImageKey)
                result.image = filter.outputImage
            }
            else if let filter = c.filter {
                if !filter.enabled {
                    continue
                }
                filter.source = IMPImage(context: filter.context, provider: result)
                result = filter.destination
            }
            c.complete?(result)
        }
        
        executeDestinationObservers(destination: result)
        
        dirty = false
        
        return result
    }
    
    //
    // optimize processing when image < GPU SIZE
    //
    private func apply(size:NSSize?, commandBuffer: MTLCommandBuffer? = nil) -> MTLTexture? {
        
        guard let input = self.source?.texture else { return nil}
        
        guard let colorSpace =  source?.colorSpace else { return nil }
        
        var currentResult = input
        
        for c in coreImageFilterList {
            
            context.execute(.sync, complete: { [weak self] in
                
                guard let self = self else { return }
                
                if let filter = c.filter {
                    filter.executeDestinationObservers(destination: filter._destination)
                }
                
            }, fail: {                
                
                NSLog("IMPFilter: applying failed.")
                
            }, action: { (commandBuffer) in
                
                let device = commandBuffer.device
                
                if let filter = c.cifilter {
                    
                    if filter.isKind(of: IMPCIFilter.self) {
                        
                        guard let f = (filter as? IMPCIFilter) else {
                            return
                        }
                        
                        let dsize = (f.destinationSize ?? size) ?? currentResult.cgsize
                        
                        let pixelFormat = currentResult.pixelFormat
                        let tmp:MTLTexture = device.make2DTexture(size: dsize, pixelFormat: pixelFormat)
                        
                        if f.source == nil {
                            f.source = IMPImage(context: self.context)
                        }
                        
                        f.source?.texture = currentResult
                        f.process(to: tmp, commandBuffer: commandBuffer)
                        
                        currentResult = tmp
                    }
                    else {
                        let dsize = currentResult.cgsize
                        let pixelFormat = currentResult.pixelFormat 
                        let tmp:MTLTexture = device.make2DTexture(size: dsize, pixelFormat: pixelFormat)

                        let kciOptions = [CIImageOption.colorSpace:colorSpace,
                                          CIContextOption.outputPremultiplied: true,
                                          CIContextOption.useSoftwareRenderer: false] as! [CIImageOption : Any]
                        
                        filter.setValue(CIImage(mtlTexture: currentResult, options: kciOptions),forKey: kCIInputImageKey)
                        
//                        filter.setValue(CIImage(mtlTexture: currentResult,
//                                                options:  convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace])),
//                                        forKey: kCIInputImageKey)
//
                        guard let image = filter.outputImage else { return }
                        
                        self.context.coreImage?.render(image,
                                                       to: tmp,
                                                       commandBuffer: commandBuffer,
                                                       bounds: image.extent,
                                                       colorSpace: colorSpace)
                        
                        currentResult = tmp
                    }
                }
                else if let filter = c.filter {
                    
                    if !filter.enabled {
                        return
                    }
                    
                    if filter.source == nil {
                        filter.source = IMPImage(context: self.context)
                    }
                    
                    filter.source?.texture = currentResult
                    if let t = filter.apply(size: filter.destinationSize ?? size ?? currentResult.cgsize,
                                            commandBuffer: commandBuffer){
                        currentResult = t
                    }
                    else {
                        return
                    }
                    
                    filter._destination.texture = currentResult
                    
                }
            })
            
            c.complete?(IMPImage(context:self.context, texture: currentResult))
        }
        return currentResult
    }
    
    
    public static func == (lhs: IMPFilter, rhs: IMPFilter) -> Bool {
        //if let ln = lhs.name, let rn = rhs.name {
        //    return ln == rn
        //}
        return lhs.name == rhs.name
    }
    
    //
    // MARK: - observers
    //    
    @discardableResult private func unsafeRemoveObserver<T>(from list: inout [IMPObserverHash<T>], _ observer:T, key aKey:String? = nil) -> String {
        let key = aKey ?? IMPObserverHash<T>.observerKey(observer)
        if let index = list.index(where: { return $0.key == key }) {
            list.remove(at: index)
        }                
        return key
    }    
    
    private func unsafeAddObserver<T>(to list:inout [IMPObserverHash<T>], _ observer:T, key aKey:String? = nil){
        let key = unsafeRemoveObserver(from: &list, observer, key: aKey)
        list.append(IMPObserverHash<T>(key:key, observer:observer))
    }
    
    @discardableResult public func addObserver<T:IMPFilter>(newSource observer:@escaping SourceUpdateHandler, key aKey:String? = nil) -> T {
        mutex.sync {
            unsafeAddObserver(to: &newSourceObservers, observer, key: aKey)
        }
        return self as! T
    }
    
    public func removeObserver(newSource observer:@escaping SourceUpdateHandler, key aKey:String? = nil) {
        mutex.sync {
            unsafeRemoveObserver(from: &newSourceObservers, observer, key: aKey)
        }
    }    
    
    @discardableResult public func addObserver<T:IMPFilter>(destinationUpdated observer:@escaping UpdateHandler, key aKey:String? = nil) -> T {
        mutex.sync {
            unsafeAddObserver(to: &destinationObservers, observer, key: aKey)
        }
        return self as! T
    }
    
    public func removeObserver(destinationUpdated observer:@escaping UpdateHandler, key aKey:String? = nil) {
        mutex.sync { 
            unsafeRemoveObserver(from: &destinationObservers, observer, key: aKey)
        }
    }
    
    @discardableResult public func addObserver<T:IMPFilter>(dirty observer:@escaping FilterHandler, key aKey:String? = nil) -> T {
        mutex.sync {             
            unsafeAddObserver(to: &dirtyObservers, observer, key: aKey)
        }
        return self as! T
    }
    
    public func removeObserver(dirty observer:@escaping FilterHandler, key aKey:String? = nil) {
        mutex.sync {
            unsafeRemoveObserver(from: &dirtyObservers, observer, key: aKey)
        }
    }
    
    @discardableResult public func addObserver<T:IMPFilter>(enabling observer:@escaping FilterHandler, key aKey:String? = nil) -> T {
        mutex.sync {            
            unsafeAddObserver(to: &enablingObservers, observer, key: aKey)
        }
        return self as! T
    }
    
    public func removeObserver(enabling observer:@escaping FilterHandler, key aKey:String? = nil) {
        mutex.sync { 
            unsafeRemoveObserver(from: &enablingObservers, observer, key: aKey)
        }
    }
    
    public func removeAllObservers(){
        mutex.sync {
            newSourceObservers.removeAll()
            destinationObservers.removeAll()
            
            root?.removeAllObservers()
            dirtyObservers.removeAll()
            enablingObservers.removeAll()
        }
    }
    
    //
    // MARK: - main filter chain operations
    //
    @discardableResult public func add<T:IMPFilter>(filter: IMPFilter,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil) -> T {
        if filter !== self {
            filter.root = self
        }
        return appendFilter(filter: FilterContainer(cifilter: nil, filter: filter, complete:complete),
                            fail: { (error) in
                                filter.root = nil
                                fail?(error)
        })
    }
    
    @discardableResult public func insert<T:IMPFilter>(filter: IMPFilter,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        if filter !== self {
            filter.root = self
        }
        return insertFilter(filter: FilterContainer(cifilter: nil, filter: filter, complete:complete), index:index,
                            fail: { (error) in
                                filter.root = nil
                                fail?(error)
        })
    }
    
    
    @discardableResult public func insert<T:IMPFilter>(filter: IMPFilter,
                                          after filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let (index, contains) = findFilter(name: filterName, isAfter: true, fail: fail)
        if contains {
            if filter !== self {
                filter.root = self
            }
            return insertFilter(filter: FilterContainer(cifilter: nil, filter: filter, complete:complete), index:index,
                                fail: { (error) in
                                    filter.root = nil
                                    fail?(error)
            })
        }
        return self as! T
    }
    
    @discardableResult public func insert<T:IMPFilter>(filter: IMPFilter,
                                          before filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        
        let (index, contains) = findFilter(name: filterName, isAfter: false, fail: fail)
        if contains {
            if filter !== self {
                filter.root = self
            }
            return insertFilter(filter: FilterContainer(cifilter: nil, filter: filter, complete:complete), index:index,
                                fail: { (error) in
                                    filter.root = nil
                                    fail?(error)
            })
        }
        return self as! T
    }
    
    
    //
    // MARK: - create filters chain
    //
    @discardableResult public func add<T:IMPFilter>(function: IMPFunction,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return appendFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), fail: fail)
    }
    
    @discardableResult public func add<T:IMPFilter>(shader: IMPShader,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLShader.register(shader: shader)
        return appendFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), fail: fail)
    }
    
    @discardableResult public func add<T:IMPFilter>(function name: String,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil) -> T {
        return add(function: IMPFunction(context: context, kernelName: name), fail: fail, complete: complete)
    }
    
    @discardableResult public func add<T:IMPFilter>(vertex: String, fragment: String,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil) -> T {
        return add(shader: IMPShader(context: context, vertexName: vertex, fragmentName: fragment), fail: fail, complete: complete)
    }
    
    @discardableResult public func add<T:IMPFilter>(filter: CIFilter,
                                       fail: FailHandler?=nil,
                                       complete: CompleteHandler?=nil)  -> T {
        return appendFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), fail: fail)
    }
    #if os(iOS)
    public func add<T:IMPFilter>(mps: MPSUnaryImageKernel, withName: String? = nil,
                    fail: FailHandler?=nil,
                    complete: CompleteHandler?=nil)   {
        if let newName = withName {
            mps.label = newName
        }
        guard let _ = mps.label else {
            fatalError(" *** IMPFilter add(mps:withName:): mps kernel should contain defined label property or withName should be specified...")
        }
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: IMPMPSUnaryKernel.make(kernel: mps))
        appendFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), fail: fail)
    }
    
    public func add<T:IMPFilter>(mps: IMPMPSUnaryKernelProvider,
                    fail: FailHandler?=nil,
                    complete: CompleteHandler?=nil)   {
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: mps)
        appendFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), fail: fail)
    }
    #endif
    
    
    //
    // MARK: - insertion at index
    //
    @discardableResult public func insert<T:IMPFilter>(function: IMPFunction,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
    }
    
    @discardableResult public func insert<T:IMPFilter>(shader: IMPShader,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLShader.register(shader: shader)
        return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
    }
    
    @discardableResult public func insert<T:IMPFilter>(function name: String,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        return insert(function: IMPFunction(context:context, kernelName:name),
                      at: index, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(vertex: String, fragment: String,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        return insert(shader: IMPShader(context:context, vertexName: vertex, fragmentName:fragment),
                      at: index, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(filter: CIFilter,
                                          at index: Int,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
    }
    
    #if os(iOS)
    @discardableResult public func insert<T:IMPFilter>(mps: MPSUnaryImageKernel, withName: String? = nil,
                       at index: Int,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        if let newName = withName {
            mps.label = newName
        }
        guard let _ = mps.label else {
            fatalError(" *** IMPFilter insert(mps:withName:): mps kernel should contain defined label property or withName should be specified...")
        }
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: IMPMPSUnaryKernel.make(kernel: mps))
        return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
    }
    
    @discardableResult public func insert<T:IMPFilter>(mps: IMPMPSUnaryKernelProvider,
                       at index: Int,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: mps)
        return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
    }
    #endif
    
    //
    // MARK: - insertion before / after
    //
    
    // Insert CIFilter before/after
    @discardableResult public func insert<T:IMPFilter>(filter: CIFilter,
                                          before filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        
        let (index, contains) = findFilter(name: filterName, isAfter: false, fail: fail)
        if contains {
            return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
        }
        return self as! T
    }
    
    @discardableResult public func insert<T:IMPFilter>(filter: CIFilter,
                                          after filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        
        let (index, contains) = findFilter(name: filterName, isAfter: true, fail: fail)
        if contains {
            return insertFilter(filter: FilterContainer(cifilter: filter, filter: nil, complete:complete), index:index, fail: fail)
        }
        return self as! T
    }
    
    // Insert IMPFunction before/after
    @discardableResult public func insert<T:IMPFilter>(function: IMPFunction,
                                          after filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return insert(filter: filter, after: filterName, fail: fail, complete: complete)
    }
    
    // Insert IMPFunction before/after
    @discardableResult public func insert<T:IMPFilter>(shader: IMPShader,
                                          after filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLShader.register(shader: shader)
        return insert(filter: filter, after: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(function: IMPFunction,
                                          before filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return insert(filter: filter, before: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(shader: IMPShader,
                                          before filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let filter = IMPCoreImageMTLShader.register(shader: shader)
        return insert(filter: filter, before: filterName, fail: fail, complete: complete)
    }
    
    // Insert IMPFunction by name before/after
    @discardableResult public func insert<T:IMPFilter>(function name: String,
                                          after filterName: String,
                                          fail: FailHandler?=nil,
                                          complete: CompleteHandler?=nil) -> T {
        let function = IMPFunction(context: context, kernelName: name)
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return insert(filter: filter, after: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(vertex: String, fragment: String,
                       after filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) -> T {
        return insert(shader: IMPShader(context:context, vertexName:vertex, fragmentName:fragment),
                      after: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(function name: String,
                       before filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) -> T {
        let function = IMPFunction(context: context, kernelName: name)
        let filter = IMPCoreImageMTLKernel.register(function: function)
        return insert(filter: filter, before: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(vertex: String, fragment: String,
                       before filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) -> T {
        return insert(shader: IMPShader(context:context, vertexName:vertex, fragmentName:fragment),
                      before: filterName, fail: fail, complete: complete)
    }
    
    // Insert MPS before/after
    #if os(iOS)
    @discardableResult public func insert<T:IMPFilter>(mps: MPSUnaryImageKernel, withName: String? = nil,
                       after filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        if let newName = withName {
            mps.label = newName
        }
        guard let _ = mps.label else {
            fatalError(" *** IMPFilter insert(mps:withName:): mps kernel should contain defined label property or withName should be specified...")
        }
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: IMPMPSUnaryKernel.make(kernel: mps))
        return insert(filter: filter, after: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(mps: IMPMPSUnaryKernelProvider,
                       after filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: mps)
        return insert(filter: filter, after: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(mps: MPSUnaryImageKernel, withName: String? = nil,
                       before filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        if let newName = withName {
            mps.label = newName
        }
        guard let _ = mps.label else {
            fatalError(" *** IMPFilter insert(mps:withName:): mps kernel should contain defined label property or withName should be specified...")
        }
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: IMPMPSUnaryKernel.make(kernel: mps))
        return insert(filter: filter, before: filterName, fail: fail, complete: complete)
    }
    
    @discardableResult public func insert<T:IMPFilter>(mps: IMPMPSUnaryKernelProvider,
                       before filterName: String,
                       fail: FailHandler?=nil,
                       complete: CompleteHandler?=nil) {
        let filter = IMPCoreImageMPSUnaryKernel.register(mps: mps)
        return insert(filter: filter, before: filterName, fail: fail, complete: complete)
    }
    #endif
    
    //
    // MARK: - remove filter from chain
    //
    public func remove(function: IMPFunction) {
        remove(filter: function.name)
    }
    
    public func remove(shader: IMPShader) {
        remove(filter: shader.name)
    }
    
    public func remove(filter name: String){
        var index = 0
        for f in coreImageFilterList{
            if let filter = f.cifilter {
                if filter.name == name {
                    coreImageFilterList.remove(at: index)
                    break
                }
            }
            else if let filter = f.filter {
                //if let fname = filter.name {
                if filter.name == name {
                    coreImageFilterList.remove(at: index)
                    break
                }
                //}
            }
            index += 1
        }
    }
    
    #if os(iOS)
    public func remove(mps: MPSUnaryImageKernel) {
        guard let name = mps.label else {
            fatalError(" *** IMPFilter: remove(mps:) mps kernel should contain defined label property...")
        }
        remove(filter: name)
    }
    
    public func remove(mps: IMPMPSUnaryKernelProvider) {
        remove(filter: mps.name)
    }
    #endif
    
    public func remove(filter: CIFilter) {
        remove(filter: filter.name)
    }
    
    public func remove(filter matchedFilter:IMPFilter){
        var index = 0
        for f in coreImageFilterList{
            if let filter = f.filter {
                if filter == matchedFilter {
                    coreImageFilterList.remove(at: index)
                    break
                }
            }
            index += 1
        }
    }
    
    public func removeAll(){
        coreImageFilterList.removeAll()
    }
    
    //
    // MARK: - internal
    //
    internal func executeNewSourceObservers(source:IMPImageProvider?){
        let observers = self.mutex.sync { Array(self.newSourceObservers) } 
        context.runOperation(self.observingType) {
            for hash in observers {
                hash.observer(source)
            }            
        }
    }
    
    internal func executeDestinationObservers(destination:IMPImageProvider?){
        if observersEnabled {
            if let d = destination {
                let observers = self.mutex.sync { Array(self.destinationObservers) }                     
                context.runOperation(self.observingType) {
                    for hash in observers {
                        hash.observer(d)
                    }
                }
            }                            
        }
    }
    
    internal func executeDirtyObservers(filter:IMPFilter){
        if observersEnabled {
            root?.executeDirtyObservers(filter: self)
            let observers = self.mutex.sync { Array(self.dirtyObservers) }
            context.runOperation(self.observingType) {
                for hash in observers {
                    hash.observer(filter,filter.source,filter._destination)
                }
            }                
        }
    }
    
    internal func executeEnablingObservers(filter:IMPFilter){
        if observersEnabled {
            let observers = self.mutex.sync { Array(self.enablingObservers) }
            context.runOperation(self.observingType) {
                for hash in observers {
                    hash.observer(filter,filter.source,filter._destination)
                }
            }                
        }
    }
    
    
    //
    // MARK: - private
    //
    
    private var root:IMPFilter? = nil {
        didSet{
            if let r = root, self !== r {
                self.observingType = r.observingType
                self.dirty = r.dirty
            }
        }
    }
    
    private lazy var _destination:IMPImageProvider   = IMPImage(context: self.context)
    
    private var newSourceObservers   = [IMPObserverHash<SourceUpdateHandler>]()
    private var destinationObservers = [IMPObserverHash<UpdateHandler>]()
    
    private var dirtyObservers       = [IMPObserverHash<FilterHandler>]()
    private var enablingObservers    = [IMPObserverHash<FilterHandler>]()
    
    private var coreImageFilterList:[FilterContainer] = [FilterContainer]()
    
    public struct FilterContainer: Equatable {
        
        var cifilter:CIFilter?        = nil
        var filter:IMPFilter?         = nil
        var complete:CompleteHandler? = nil
        
        public static func == (lhs: FilterContainer, rhs: FilterContainer) -> Bool {
            if let lf = lhs.cifilter, let rf = rhs.cifilter {
                return lf.name == rf.name
            }
            else if let lf = lhs.filter, let rf = rhs.filter {
                return lf == rf
            }
            return false
        }
    }
    
    private func appendFilter<T:IMPFilter>(filter:FilterContainer,
                              fail: FailHandler?=nil) -> T {
        if coreImageFilterList.contains(filter) == false {
            coreImageFilterList.append(filter)
        }
        else{
            fail?(.AlreadyExist)
        }
        return self as! T
    }
    
    private func insertFilter<T:IMPFilter>(filter:FilterContainer,
                              index: Int,
                              fail: FailHandler?=nil) -> T {
        if coreImageFilterList.contains(filter) == false {
            coreImageFilterList.insert(filter, at: index)
        }
        else{
            fail?(.AlreadyExist)
        }
        return self as! T
    }
    
    private func findFilter(name: String, isAfter: Bool, fail: FailHandler?=nil) -> (Int,Bool) {
        var index = 0
        var contains = false
        for f in coreImageFilterList{
            if let filter = f.filter{
                if filter.name == name {
                    contains = true
                    if isAfter {
                        index += 1
                    }
                    break
                }
            } else if let filter = f.cifilter {
                if filter.name == name {
                    contains = true
                    if isAfter {
                        index += 1
                    }
                    break
                }
            }
            index += 1
        }
        if !contains {
            fail?(.NotFound)
            return (0,false)
        }
        return (index,true)
    }
    
    private lazy var resampleKernel:IMPFunction = IMPFunction(context: self.context/*, name: self.name + "Common resampler kernel"*/)
    private lazy var resampleShader:IMPShader = IMPShader(context: self.context/*, name: self.name + "Common resampler shader"*/)
    
    private lazy var resampler:IMPCIFilter = {
        let v = self.prefersRendering ?
            IMPCoreImageMTLShader.register(shader: self.resampleShader)  :
            IMPCoreImageMTLKernel.register(function: self.resampleKernel)
        v.source = IMPImage(context: self.context)
        return v
    }()
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCIImageOptionDictionary(_ input: [String: Any]?) -> [CIImageOption: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (CIImageOption(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCIImageOption(_ input: CIImageOption) -> String {
	return input.rawValue
}
