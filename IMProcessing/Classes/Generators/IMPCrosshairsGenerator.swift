//
//  IMPCrosshairGenerator.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPDrawPointsShader: IMPShader {
    
    public var points = [IMPCorner]() {
        didSet{
            if points.count > 1 {
                _pointsBuffer = context.device.makeBuffer(bytes: points, length: points.count * MemoryLayout<IMPCorner>.size, options: [])!
            }
        }
    }
    
    override public var vertexDescriptor: MTLVertexDescriptor? {
        return nil
    }
    
    public var pointsBuffer:MTLBuffer {
        return _pointsBuffer
    }
    
    private lazy var _pointsBuffer: MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<IMPCorner>.size, options: [])!
}

class IMPDrawPointsCoreMTLShader: IMPCoreImageMTLShader {
    override public func textureProcessor(_ commandBuffer: MTLCommandBuffer,
                                          _ threadgroups: MTLSize,
                                          _ threadsPerThreadgroup: MTLSize,
                                          _ sourceTexture: MTLTexture,
                                          _ destinationTexture: MTLTexture) {
        
        if let shader   = self.shader as? IMPDrawPointsShader {            
            shader.context.runOperation {
                let points = shader.points
                
                let renderEncoder = shader.commandEncoder(from: commandBuffer, width: destinationTexture)
                
                renderEncoder?.setVertexBuffer(shader.pointsBuffer, offset: 0, index: 0)
                renderEncoder?.setFragmentTexture(sourceTexture, index:0)
                
                if let handler = shader.optionsHandler, let render = renderEncoder{
                    handler(shader, render, sourceTexture, destinationTexture)
                }
                
                renderEncoder?.drawPrimitives(type: .point,
                                             vertexStart: 0,
                                             vertexCount: points.count,
                                             instanceCount: 4)
                renderEncoder?.endEncoding()
            }
        }
    }
}


public class IMPCrosshairsGenerator: IMPFilter {
    
    public static let defaultAdjustment = IMPAdjustment(blending: IMPBlending(mode: .normal, opacity: 1))
    
    public var adjustment:IMPAdjustment!{
        didSet{
            adjustmentBuffer = adjustmentBuffer ?? context.device.makeBuffer(length: MemoryLayout.size(ofValue: adjustment), options: [])
            memcpy(adjustmentBuffer.contents(), &adjustment, adjustmentBuffer.length)
        }
    }
    
    var adjustmentBuffer:MTLBuffer!
    
    public var points:[IMPCorner] {
        set{
            pointsShader.points = newValue
            dirty = true
        }
        get{ return pointsShader.points }
    }
    
    static var defaultWidth:Float = 15
    static var defaultColor:float4 = float4(0,1,0.3,1)
    
    public var width:Float = IMPCrosshairsGenerator.defaultWidth {
        didSet{
            memcpy(widthBuffer.contents(), &width, widthBuffer.length)
            dirty = true
        }
    }
    
    public var color:float4 = IMPCrosshairsGenerator.defaultColor {
        didSet{
            memcpy(colorBuffer.contents(), &color, colorBuffer.length)
            dirty = true
        }
    }

    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "CrosshairGenerator")
        shader.processor = shader.textureProcessor
        add(filter: shader)
        add(shader: blendShader){ (source) in
            complete?(source)
        }

        width = IMPCrosshairsGenerator.defaultWidth
        color = IMPCrosshairsGenerator.defaultColor
        adjustment = IMPCrosshairsGenerator.defaultAdjustment
    }
    
    private lazy var pointsShader:IMPDrawPointsShader =  {
        let s = IMPDrawPointsShader(context: self.context,
                                    vertexName: "vertex_crosshair",
                                    fragmentName: "fragment_crosshair")
        s.optionsHandler = { (shader, commandEncoder, input, output) in
            commandEncoder.setVertexBuffer(self.widthBuffer, offset: 0, index: 1)
            commandEncoder.setFragmentBuffer(self.colorBuffer, offset: 0, index: 0)
        }
        return s
    }()
    
    lazy var blendShader:IMPShader   = {
        let s = IMPShader(context: self.context,
                          fragmentName: "fragment_blendTextureSource")
        s.optionsHandler = { (shader,commandEncoder, input, output) in
            commandEncoder.setFragmentBuffer(self.adjustmentBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture((self.source?.texture)!, index:1)
        }
        return s
    }()
    
    private lazy var shader:IMPCIFilter = {
        return IMPDrawPointsCoreMTLShader.register(shader: self.pointsShader,
                                                   filter: IMPDrawPointsCoreMTLShader())
    }()

    private lazy var widthBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: self.width), options: [])!
    private lazy var colorBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: self.color), options: [])!

}
