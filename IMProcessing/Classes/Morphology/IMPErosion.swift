//
//  IMPErosion.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 22/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPErosion: IMPMorphology {
    
    required public init(context: IMPContext, name: String? = nil) {
        super.init(context: context, kernelName: "kernel_erosion", name: name)
    }
    
    required public init(context: IMPContext, kernelName: String, name: String?) {
        fatalError("init(context:kernelName:name:) has not been implemented")
    }
    
}
