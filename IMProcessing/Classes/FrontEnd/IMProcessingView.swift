//
//  IMProcessingView.swift
//  IMProcessing
//
//  Created by denis svinarchuk on 03.12.2017.
//

//
//  IMPMetalView.swift
//  Dehancer mLut Maker
//
//  Created by denis svinarchuk on 02.12.2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import MetalKit

open class IMProcessingView: MTKView {
        
    public var placeHolderColor:NSColor? {
        didSet{
            if let color = placeHolderColor{
                __placeHolderColor = color.rgba
            }
            else {
                __placeHolderColor = float4(1)
            }
        }
    }
    
    public var image:IMPImageProvider? {
        didSet{            
            refreshQueue.async(flags: [.barrier]) {                
                self.__source = self.image
                if self.image == nil /*&& self.__placeHolderColor == nil*/ {
                    return
                }
                if self.isPaused  {
                    self.draw()
                }
            }
        }
    }
    
    private var __source:IMPImageProvider? 
    private var __placeHolderColor = float4(1)  

    public override init(frame frameRect: CGRect, device: MTLDevice?=nil) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        configure()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        configure()
    }
        
    open func configure() {
        delegate = self
        isPaused = true
        enableSetNeedsDisplay = false
        framebufferOnly = true
        clearColor = MTLClearColorMake(0, 0, 0, 0)
    }
        
    private lazy var commandQueue:MTLCommandQueue = self.device!.makeCommandQueue(maxCommandBufferCount: IMProcessingView.maxFrames)!
    
    private static let maxFrames = 1  
    
    private let mutex = DispatchSemaphore(value: IMProcessingView.maxFrames)        
    private var framesTimeout:UInt64 = 5
        
    fileprivate func refresh(){
        
        guard
            let pipeline = ((self.__source?.texture == nil)  ? self.placeHolderPipeline : self.pipeline), 
            let commandBuffer = self.__source?.context.commandBuffer ?? commandQueue.makeCommandBuffer() else {
                return             
        }
        
        if !self.isPaused {
            guard self.mutex.wait(timeout: DispatchTime(uptimeNanoseconds: 1000000000 * framesTimeout)) == .success else {
                return                         
            }
        }

        self.render(commandBuffer: commandBuffer, texture: self.__source?.texture, with: pipeline){
            if !self.isPaused {
                self.mutex.signal()
            }
        }
    }
    
    fileprivate func render(commandBuffer:MTLCommandBuffer, texture:MTLTexture?, with pipeline: MTLRenderPipelineState,
                            complete: @escaping () -> Void) {        
        
                
        commandBuffer.label = "Frame command buffer"
        
        commandBuffer.addCompletedHandler{ commandBuffer in            
            complete()            
            return
        }
        
        if  let currentDrawable = self.currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor,               
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor){
            
            renderEncoder.label = "IMPProcessingView"
            
            renderEncoder.setRenderPipelineState(pipeline)
            
            renderEncoder.setVertexBuffer(vertexBuffer, offset:0, index:0)
            if let texture = texture {
                renderEncoder.setFragmentTexture(texture, index:0)
            }
            else {
                renderEncoder.setFragmentBytes(&__placeHolderColor, length: MemoryLayout.size(ofValue: __placeHolderColor), index: 0)
            }
                        
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart:0, vertexCount:4, instanceCount:1)
            
            renderEncoder.endEncoding()
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()  
            commandBuffer.waitUntilCompleted()
        }
        else {
            complete()            
        }
    }
    
    private static var library = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!    
    
    private lazy var fragment = IMProcessingView.library.makeFunction(name: "fragment_passview")
    private lazy var fragmentPlaceHolder = IMProcessingView.library.makeFunction(name: "fragment_placeHolderView")
    private lazy var vertex   = IMProcessingView.library.makeFunction(name: "vertex_passview")    
    
    private lazy var pipeline:MTLRenderPipelineState? = {
        do {
            let descriptor = MTLRenderPipelineDescriptor()
            
            descriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
            
            descriptor.vertexFunction   = self.vertex
            descriptor.fragmentFunction = self.fragment
            
            return try self.device!.makeRenderPipelineState(descriptor: descriptor)
        }
        catch let error as NSError {
            NSLog("IMPView error: \(error)")
            return nil
        }
    }()
    
    private lazy var placeHolderPipeline:MTLRenderPipelineState? = {
        do {
            let descriptor = MTLRenderPipelineDescriptor()
            
            descriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
            
            descriptor.vertexFunction   = self.vertex
            descriptor.fragmentFunction = self.fragmentPlaceHolder
            
            return try self.device!.makeRenderPipelineState(descriptor: descriptor)
        }
        catch let error as NSError {
            NSLog("IMPView error: \(error)")
            return nil
        }
    }()
    
    private static let viewVertexData:[Float] = [
        -1.0,  -1.0,  0.0,  1.0,
        1.0,  -1.0,  1.0,  1.0,
        -1.0,   1.0,  0.0,  0.0,
        1.0,   1.0,  1.0,  0.0,
        ]
    
    private lazy var vertexBuffer:MTLBuffer? = {
        let v = self.device?.makeBuffer(bytes: IMProcessingView.viewVertexData, length: MemoryLayout<Float>.size*IMProcessingView.viewVertexData.count, options: [])
        v?.label = "Vertices"
        return v
    }()
    
    public var refreshQueue = DispatchQueue(label:  String(format: "com.dehancer.metal.view.refresh-%08x%08x", arc4random(), arc4random()))
}

extension IMProcessingView: MTKViewDelegate {
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        self.refresh()
    }    
    
}
