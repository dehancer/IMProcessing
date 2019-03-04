//
//  IMPDevice.swift
//  Dehancer Desktop
//
//  Created by denn on 02/03/2019.
//  Copyright © 2019 Dehancer. All rights reserved.
//

import IMProcessing

public class IMPDevice {
    
    public static let shared = IMPDevice()
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let defaultLibrary:MTLLibrary 

    #if (_USE_BUNDLE_METAL_LIB_)
    public let library: MTLLibrary
    #endif

    public lazy var passthroughRenderState: MTLRenderPipelineState = {
        let (pipelineState, _) = generateRenderPipelineState(device:self,
                                                             vertexFunctionName:"oneInputVertex",
                                                             fragmentFunctionName:"passthroughFragment",
                                                             operationName:"Passthrough")
        return pipelineState
    }()
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError("Could not create Metal Device")}
        self.device = device
        
        guard let queue = self.device.makeCommandQueue() else {fatalError("Could not create command queue")}
        self.commandQueue = queue
        
        guard let dl = self.device.makeDefaultLibrary() else {fatalError("Could not create default library")}
        self.defaultLibrary = dl 
        
        #if (_USE_BUNDLE_METAL_LIB_)

        do {
            
            let frameworkBundle = Bundle(for: IMPDevice.self)
            let metalLibraryPath = frameworkBundle.path(forResource: "default", ofType: "metallib")            
            self.library = try device.makeLibrary(filepath:metalLibraryPath)
            
        } catch {
            fatalError("Could not load library")
        }
        #endif
    }
}
