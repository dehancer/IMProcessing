//
//  MTLShader.swift
//  Pods
//
//  Created by denis svinarchuk on 19.02.17.
//
//

import Metal
import CoreImage

public class IMPCoreImageMTLShader: IMPCIFilter{
    
    override public var destinationSize: NSSize? {
        set{
            shader?.destinationSize = newValue
        }
        get{
            return shader?.destinationSize
        }
    }

    static var registeredShaderList:[IMPShader] = [IMPShader]()
    static var registeredFilterList:[String:IMPCoreImageMTLShader] = [String:IMPCoreImageMTLShader]()
    
    static func register(shader:IMPShader, filter: IMPCoreImageMTLShader? = nil) -> IMPCoreImageMTLShader {
        if let filter = registeredFilterList[shader.name] {
            return filter
        }
        else {
            let filter = filter ?? IMPCoreImageMTLShader()
            if #available(iOS 10.0, *) {
                filter.name = shader.name
            } else {
                // Fallback on earlier versions
                fatalError("IMPCoreImageMPSUnaryKernel: ios >10.0 supports only")
            }
            filter.shader = shader
            filter.context = shader.context
            registeredFilterList[shader.name] = filter
            return filter
        }
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        return self.shader?.name == (object as? IMPCoreImageMTLShader)?.shader?.name
    }
    
    var shader: IMPShader? {
        didSet{
            guard let f = shader else {
                return
            }
            if let index = IMPCoreImageMTLShader.registeredShaderList.index(of: f) {
                kernelIndex = index
            }
            else {
                kernelIndex = IMPCoreImageMTLShader.registeredShaderList.count
                IMPCoreImageMTLShader.registeredShaderList.append(f)
            }
        }
    }
    
    override public func textureProcessor(_ commandBuffer: MTLCommandBuffer,
                                   _ threadgroups: MTLSize,
                                   _ threadsPerThreadgroup: MTLSize,
                                   _ sourceTexture: MTLTexture,
                                   _ destinationTexture: MTLTexture) {
                
        if let shader   = self.shader,
            let vertices = shader.vertices {
            
            guard let renderEncoder = shader.commandEncoder(from: commandBuffer, width: destinationTexture) else { return }
            
            renderEncoder.setVertexBuffer(shader.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(sourceTexture, index:0)
            
            if let handler = shader.optionsHandler {
                handler(shader, renderEncoder, sourceTexture, destinationTexture)
            }
            
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: 0,
                                         vertexCount: vertices.count,
                                         instanceCount: vertices.count/3)
            renderEncoder.endEncoding()
        }
    }    
}

