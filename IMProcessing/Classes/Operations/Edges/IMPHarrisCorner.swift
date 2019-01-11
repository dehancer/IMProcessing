//
//  IMPHarrisCorner.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPHarrisCorner: IMPFilter{

    public static let defaultSensitivity:Float = 16

    public var sensitivity:Float = IMPHarrisCorner.defaultSensitivity {
        didSet{
            //sensitivityBuffer <= sensitivity
            sensitivityBuffer.copy(from: sensitivity)
            dirty = true
        }
    }
    
    public let functionName: String
    
    public required init(context: IMPContext, name: String?=nil) {
        self.functionName = "fragment_harrisCorner"
        super.init(context: context, name: name)
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "HarrisCorner")
        super.configure()
        add(shader:derivative){ (source) in
            complete?(source)
        }
    }
    
    private lazy var derivative:IMPShader = {
        let s = IMPShader(context: self.context,
                          fragmentName: self.functionName)        
        s.optionsHandler = { (shader, commandEncoder, input, output) in
            commandEncoder.setFragmentBuffer(self.sensitivityBuffer, offset: 0, index: 0)
        }
        return s
    }()
    
    private lazy var sensitivityBuffer:MTLBuffer =  self.context.makeBuffer(from:IMPHarrisCorner.defaultSensitivity)
    
}
