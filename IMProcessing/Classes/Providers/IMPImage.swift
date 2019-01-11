//
//  IMPImage.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 12.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa    
#endif

import CoreImage
import simd
import Metal
import AVFoundation
import ImageIO

open class IMPImage: IMPImageProvider {
    
    public let mutex = IMPSemaphore()
    
    public func removeObserver(optionsChanged observer: @escaping ObserverType) {
        mutex.sync { () -> Void in
            unsafeRemoveObserver(optionsChanged: observer)
        }
    }
                
    public func addObserver(optionsChanged observer: @escaping ObserverType) {
        mutex.sync { () -> Void in
            let key = unsafeRemoveObserver(optionsChanged: observer)
            self.filterObservers.append(IMPObserverHash<ObserverType>(key:key,observer: observer))
        }
    }
    
    @discardableResult public func unsafeRemoveObserver(optionsChanged observer: @escaping ObserverType) -> String {
        let key = IMPObserverHash<ObserverType>.observerKey(observer)
        if let index = self.filterObservers.index(where: { return $0.key == key }) {
            self.filterObservers.remove(at: index)
        } 
        return key
    }
    
    public func removeObservers() {
        mutex.sync { () -> Void in
            self.filterObservers.removeAll()
        }
    }
    
    public let storageMode: IMPImageStorageMode
    
    public var orientation = IMPImageOrientation.up

    public let context: IMPContext
    
    public var texture: MTLTexture? {
        set{
            self._texture = newValue
            self._image = nil                
        }
        get{
            if _texture == nil && _image != nil {
                render(to: &_texture) { (texture,command) in
                    let observers = self.mutex.sync { return [IMPObserverHash<ObserverType>](self.filterObservers) }
                    for hash in observers {
                        hash.observer(self)
                    }
                }                   
            }
            return _texture                
        }
    }
    
    open var image: CIImage? {
        set{
            _texture?.setPurgeableState(.empty)
            _texture = nil
            _image = newValue
        }
        get {
            if _image == nil && _texture != nil {
                _image = CIImage(mtlTexture: _texture!, options:  convertToOptionalCIImageOptionDictionary([convertFromCIImageOption(CIImageOption.colorSpace): colorSpace]))
                
                let observers = self.mutex.sync { return [IMPObserverHash<ObserverType>](self.filterObservers) }
                
                for hash in observers {
                    hash.observer(self)
                }
            }
            return _image
        }
    }
    
    public var size: NSSize? {
        get{
            return _image?.extent.size ?? _texture?.cgsize
        }
    }
    
    fileprivate var _image:CIImage? = nil
    fileprivate var _texture:MTLTexture? = nil
    
    public lazy var videoCache:IMPVideoTextureCache = {
        return IMPVideoTextureCache(context: self.context)
    }()
    
    //
    // http://stackoverflow.com/questions/12524623/what-are-the-practical-differences-when-working-with-colors-in-a-linear-vs-a-no
    //
    lazy public var colorSpace:CGColorSpace = {
        return IMProcessing.colorSpace.cgColorSpace
    }()
    
    public required init(context: IMPContext, storageMode:IMPImageStorageMode? = .shared) {
        self.context = context
        
        if storageMode != nil {
            self.storageMode = storageMode!
        }
        else {
            self.storageMode = .shared
        }
    }
    
    private var filterObservers = [IMPObserverHash<ObserverType>]() //[((IMPImageProvider) -> Void)]()
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
