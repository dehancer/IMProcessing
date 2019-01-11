//
//  IMPAdaptiveThreshold.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 31.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPAdaptiveThreshold: IMPFilter {
    
    public var blurRadius:Float = 4
    
    
    public override func configure(complete: IMPFilterProtocol.CompleteHandler?) {
        extendName(suffix: "AdaptiveThreshold")
        super.configure()
        
        boxBlur.radius = blurRadius
        
        add(function: luminance){ (source) in
            self.luminanceOutput = source
        }
        add(filter: boxBlur)
        add(function: adaptiveKernel) { (source) in
            complete?(source)
        }
    }
    
    private lazy var luminance:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_luminance")
    private lazy var boxBlur:IMPBoxBlur = IMPBoxBlur(context:self.context)

    
    private lazy var adaptiveKernel:IMPFunction = {
       let f = IMPFunction(context: self.context, kernelName: "kernel_adaptiveThreshold")
        
        f.optionsHandler = { (function,command,source,destination) in
            if let text = self.luminanceOutput?.texture{
                command.setTexture(text,index:2)
            }
        }
        
        return f
    }()

    
    private var luminanceOutput:IMPImageProvider?
}
