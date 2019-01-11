//
//  IMPTypeAliases .swift
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

import simd
import Metal

#if os(iOS)
    public typealias NSImage  = UIImage
    public typealias NSColor  = UIColor
    public typealias NSRect   = CGRect
    public typealias NSPoint  = CGPoint
    public typealias NSSize   = CGSize
#endif
