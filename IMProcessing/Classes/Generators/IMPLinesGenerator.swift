//
//  IMPLinesGenerator.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 12.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal


class IMPDrawLinesCoreMTLShader: IMPCoreImageMTLShader {
    override public func textureProcessor(_ commandBuffer: MTLCommandBuffer,
                                          _ threadgroups: MTLSize,
                                          _ threadsPerThreadgroup: MTLSize,
                                          _ sourceTexture: MTLTexture,
                                          _ destinationTexture: MTLTexture) {
        
        if let shader   = self.shader as? IMPDrawPointsShader {
            let points = shader.points
            
            let renderEncoder = shader.commandEncoder(from: commandBuffer, width: destinationTexture)
            
            renderEncoder?.setVertexBuffer(shader.pointsBuffer, offset: 0, index: 0)
            renderEncoder?.setFragmentTexture(sourceTexture, index:0)
            
            if let handler = shader.optionsHandler, let render = renderEncoder {
                handler(shader, render, sourceTexture, destinationTexture)
            }
            
            renderEncoder?.drawPrimitives(type: .line,
                                         vertexStart: 0,
                                         vertexCount: points.count,
                                         instanceCount: points.count/2)
            renderEncoder?.endEncoding()
        }
    }
}


public class IMPLinesGenerator: IMPFilter {
    
    public static let defaultAdjustment = IMPAdjustment(blending: IMPBlending(mode: .normal, opacity: 1))
    
    public var adjustment:IMPAdjustment!{
        didSet{
            adjustmentBuffer = adjustmentBuffer ?? context.device.makeBuffer(length: MemoryLayout.size(ofValue: adjustment), options: [])
            memcpy(adjustmentBuffer.contents(), &adjustment, adjustmentBuffer.length)
        }
    }
    
    public override var source: IMPImageProvider? {
        didSet{
            updateLines()
        }
    }
    
    var adjustmentBuffer:MTLBuffer!
    
    public var lines:[IMPLineSegment] {
        set{
            _lines = newValue
            updateLines()
            dirty = true
        }
        get{
            return _lines
        }
    }
    private var _lines = [IMPLineSegment]()
    
    func updateLines()  {
//        pointsShader.points = [IMPCorner]()
//        guard let size = source?.size else { return }
//        
//        //let thick = float2(1/size.width.float,1/size.height.float)
//        
//        for p in _lines {
//            //pointsShader.points.append(p.p0)
//            //pointsShader.points.append(p.p1)
//            
//            //for x in stride(from: -width/2, to: width/2, by: 1) {
//                //pointsShader.points.append(p.p0+thick)
//                //pointsShader.points.append(p.p1+thick)
//            //}
//        }
//        
////        for p in _lines {
//////            for x in stride(from: -width/2, to: width/2, by: 1) {
////            pointsShader.points.append(p.p0+thick)
////            pointsShader.points.append(p.p1+thick)
//////            }
////        }
    }
    
    static var defaultWidth:Float = 2
    static var defaultColor:float4 = float4(1,1,0.3,1)
    
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
        super.configure()
        
        shader.processor = shader.textureProcessor
        
        width = IMPLinesGenerator.defaultWidth
        color = IMPLinesGenerator.defaultColor
        adjustment = IMPLinesGenerator.defaultAdjustment

        add(filter: shader)
        add(shader: blendShader){ (source) in
            complete?(source)
        }
    }
    
    private lazy var pointsShader:IMPDrawPointsShader =  {
        let s = IMPDrawPointsShader(context: self.context,
                                    vertexName: "vertex_crosshair",
                                    fragmentName: "fragment_line")
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
        return IMPDrawLinesCoreMTLShader.register(shader: self.pointsShader, filter: IMPDrawLinesCoreMTLShader())
    }()
    
    private lazy var widthBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: self.width), options: [])!
    private lazy var colorBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout.size(ofValue: self.color), options: [])!
    
}
