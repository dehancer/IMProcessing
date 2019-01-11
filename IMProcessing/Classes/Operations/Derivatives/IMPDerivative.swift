//
//  IMPOperator.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPDerivative: IMPFilter{
    
    public var texelRadius:Float = 1 { didSet{ dirty = true } }
    
    public required init(context: IMPContext, name: String?=nil, functionName: String) {
        self.functionName = functionName
        super.init(context: context, name: name)
    }
    
    public required init(context: IMPContext, name: String?=nil) {
        fatalError("IMPBasicDerivative.init(context:name:) has not been implemented, use init(context:name:functionName:)")
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "Derivative" + ":" + functionName)
        super.configure()
        add(shader:derivative){ (source) in
            complete?(source)
        }
    }
    
    open func optionsHandler(shader:IMPShader, command:MTLRenderCommandEncoder, inputTexture:MTLTexture?, outputTexture:MTLTexture?){}
    
    private let functionName: String

    private lazy var derivative:IMPShader = {
        let s = IMPShader(context: self.context,
                          fragmentName: self.functionName)
        
        s.optionsHandler = { (shader, commandEncoder, input, output) in
            commandEncoder.setFragmentBytes(&self.texelRadius,length:MemoryLayout<Float>.size,index:0)
            self.optionsHandler(shader: shader, command: commandEncoder, inputTexture: input, outputTexture: output)
        }
        return s
    }()
}
