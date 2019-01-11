//
//  IMPCLutTransform.swift
//  IMProcessing
//
//  Created by denn on 12.08.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Foundation

open class IMPCLutTransform: IMPFilter {
    
//    public var rgb:float3 {
//        set{ reference = space.from(.rgb, value: newValue) }
//        get { return space.to(.rgb, value: reference) }
//    }
//    
//    public var reference:float3            = float3(0)   { didSet{ dirty = true } }
//    
    public var space:IMPColorSpace         = .rgb        {
        didSet{
            //reference = space.from(oldValue, value: reference);
            dirty = true }
    }
    
    open override func configure(complete: IMPFilter.CompleteHandler?) {
        super.extendName(suffix: "Commont Lut Transformation")
        super.configure(complete: complete)
    }
}
