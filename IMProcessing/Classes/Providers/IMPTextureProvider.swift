//
//  IMPTextureProvider.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import Metal

public extension Array where Element : Equatable {
    public mutating func removeObject(object : Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}

public protocol IMPTextureProvider{
    var texture:MTLTexture?{ get set }
}

public extension IMPTextureProvider {
    public var cgsize:NSSize?  { return texture?.cgsize}
    public var width:Int?      { return texture?.width }
    public var height:Int?     { return texture?.height }
    public var depth:Int?      { return texture?.depth }
}

public extension IMPTextureProvider {
    public var label:String? {
        set { texture?.label = newValue }
        get { return texture?.label}
    }
}
