//
//  IMPShader.swift
//  Pods
//
//  Created by denis svinarchuk on 19.02.17.
//
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import Metal
import simd

public protocol IMPShaderProvider: IMPDestinationSizeProvider {
    var backgroundColor:NSColor {get set}
}

extension IMPShaderProvider{
    public var clearColor:MTLClearColor {
        get {
            let rgba = backgroundColor.rgba
            let color = MTLClearColor(red:   rgba.r.double,
                                      green: rgba.g.double,
                                      blue:  rgba.b.double,
                                      alpha: rgba.a.double)
            return color
        }
    }
}

open class IMPShader: IMPContextProvider, IMPShaderProvider, IMPDestinationSizeProvider, Equatable {
   
    public var destinationSize: NSSize?
   
    public var backgroundColor: NSColor = NSColor.clear {
        didSet{
            renderPassDescriptor.colorAttachments[0].clearColor  = clearColor
        }
    }
    
    public var pixelFormat = IMProcessing.colors.pixelFormat {
        didSet{
            if oldValue != pixelFormat {
                pipeline = makePipeline()
            }
        }
    }
    
    public let vertexName:String
    public let fragmentName:String
    public var context:IMPContext
    public var name:String {
        return _name
    }
    
    public var verticesBuffer:MTLBuffer {
        return _verticesBuffer
    }
    
    public var vertices:IMPVertices! {
        didSet{
            _verticesBuffer = context.device.makeBuffer(bytes: vertices.raw, length: vertices.length, options: [])
        }
    }
    
    public func commandEncoder(from buffer: MTLCommandBuffer, width destination: MTLTexture?) -> MTLRenderCommandEncoder? {
        
        //let t = (pixelFormat != destination?.pixelFormat ?
        //    destination?.makeTextureView(pixelFormat: pixelFormat) : destination)
        
        if let pf = destination?.pixelFormat {
            if pixelFormat != pf {
                pixelFormat = pf
            }
        }
        
        renderPassDescriptor.colorAttachments[0].texture = destination
        
        let encoder = buffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.setCullMode(.front)
        encoder?.setRenderPipelineState(pipeline!)
        return encoder
    }

    
    public var optionsHandler:((
        _ function:IMPShader,
        _ command:MTLRenderCommandEncoder,
        _ inputTexture:MTLTexture?,
        _ outputTexture:MTLTexture?)->Void)? = nil
    
    
    public var library:MTLLibrary {
        return _library
    }
    
    public lazy var pipeline:MTLRenderPipelineState? = {
        return self.makePipeline()
    }()
    
    let renderPipelineDescription = MTLRenderPipelineDescriptor()

    func makePipeline() -> MTLRenderPipelineState? {
        do {
            
            if let vertexDescriptor = self.vertexDescriptor {
                renderPipelineDescription.vertexDescriptor = vertexDescriptor
            }
            renderPipelineDescription.colorAttachments[0].pixelFormat = pixelFormat
            renderPipelineDescription.vertexFunction   = library.makeFunction(name: vertexName)
            renderPipelineDescription.fragmentFunction = library.makeFunction(name: fragmentName)
            
            return try context.device.makeRenderPipelineState(descriptor: renderPipelineDescription)
        }
        catch let error as NSError{
            fatalError(" *** IMPShader: \(error)")
        }
    }
    
    public func updateShader(source: String){
        context.runOperation(.async) {
            do {
                self._library = try self.context.makeLibrary(source: source)
                self.pipeline = self.makePipeline()
                guard (self.pipeline != nil) else {
                    fatalError("IMPShader could not found function names...")
                }
            }
            catch let error {
                fatalError("IMPShader could not be compiled from source: \(error)")
            }
        }
    }
    
    public required init(context:IMPContext,
                         vertexName:String = "vertex_passthrough",
                         fragmentName:String = "fragment_passthrough",
                         name:String? = nil,
                         shaderSource:String? = nil,
                         vertexDescriptor:MTLVertexDescriptor? = nil) {
        self.context = context
        self.vertexName = vertexName
        self.fragmentName = fragmentName
        if let vd = vertexDescriptor {
            self._vertexDescriptor = vd
        }
        if name != nil {
            self._name = String.uniqString() + ":" + name!
        }
        else {
            self._name = context.uid + ":"  + String.uniqString() + ":" + self.vertexName+":"+self.fragmentName
        }
        defer {
            if let s = shaderSource  {
                updateShader(source:s)
            }
            vertices = IMPPhotoPlate()
        }
    }
    
    public static func == (lhs: IMPShader, rhs: IMPShader) -> Bool {
        return lhs.name == rhs.name
    }
    
    private lazy var _library:MTLLibrary = self.context.defaultLibrary
        
    private lazy var _vertexDescriptor:MTLVertexDescriptor = {
        var v = MTLVertexDescriptor()
        v.attributes[0].format = .float3
        v.attributes[0].bufferIndex = 0
        v.attributes[0].offset = 0
        v.attributes[1].format = .float3
        v.attributes[1].bufferIndex = 0
        v.attributes[1].offset = MemoryLayout<float3>.size
        v.layouts[0].stride = MemoryLayout<IMPVertex>.size
        
        return v
    }()

    open var vertexDescriptor:MTLVertexDescriptor? {
        return _vertexDescriptor
    }
    
    private lazy var renderPassDescriptor:MTLRenderPassDescriptor = {
        let r = MTLRenderPassDescriptor()
        r.colorAttachments[0].loadAction  = .clear
        r.colorAttachments[0].clearColor  = self.clearColor
        r.colorAttachments[0].storeAction = .store
        return r
    }()

    private lazy var _name:String = self.vertexName + ":" + self.fragmentName
    private var _verticesBuffer: MTLBuffer!
}
