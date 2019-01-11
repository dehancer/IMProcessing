//
//  IMPMorphology.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 22/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import simd

open class IMPMorphology: IMPTwoPass {
    
    public typealias Dimensions = (width:Int,height:Int)
    
    public var dimensions:Dimensions = (width:3,height:3) {
        didSet{
            dirty = true
        }
    }
    
    open override func optionsHandler(passnumber: IMPTwoPass.PassNumber,
                                      function: IMPFunction,
                                      command: MTLComputeCommandEncoder,
                                      inputTexture: MTLTexture?,
                                      outputTexture: MTLTexture?) {
        var d:uint = passnumber == .first ? uint(self.dimensions.width) : uint(self.dimensions.height)
        command.setBytes(&d,length:MemoryLayout<uint>.size,index:1)
    }
}
