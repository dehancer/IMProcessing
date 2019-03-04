//
//  IMPBuffer.swift
//  Dehancer Desktop
//
//  Created by denn on 02/03/2019.
//  Copyright © 2019 Dehancer. All rights reserved.
//

import MetalKit

public let standardVertices:[Float] = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]

public extension MTLCommandBuffer {
    
    public func renderQuad(state:MTLRenderPipelineState,
                    sources:[UInt:MTLTexture],
                    destination:MTLTexture,
                    normalized:Bool = true,
                    vertices:[Float] = standardVertices) {
        
        let vertexBuffer = IMPDevice.shared
            .device.makeBuffer(bytes: vertices,
                               length: vertices.count * MemoryLayout<Float>.size,
                               options: [])!
        
        vertexBuffer.label = "Vertices"
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = destination
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(state)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for textureIndex in 0..<sources.count {
            let currentTexture = sources[UInt(textureIndex)]!
            
            let xLimit:Float
            let yLimit:Float
            if normalized {
                xLimit = 1.0
                yLimit = 1.0
            } else {
                xLimit = Float(currentTexture.width)
                yLimit = Float(currentTexture.height)
            }
            
            let inputTextureCoordinates =  [0.0, 0.0, xLimit, 0.0, 0.0, yLimit, xLimit, yLimit]
            
            let textureBuffer = IMPDevice.shared
                .device.makeBuffer(bytes: inputTextureCoordinates,
                                   length: inputTextureCoordinates.count * MemoryLayout<Float>.size,
                                   options: [])!
            
            textureBuffer.label = "Texture Coordinates"
            
            renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1 + textureIndex)
            renderEncoder.setFragmentTexture(currentTexture, index: textureIndex)
        }
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

public func generateRenderPipelineState(device:IMPDevice,
                                 vertexFunctionName:String,
                                 fragmentFunctionName:String,
                                 operationName:String) -> (MTLRenderPipelineState, [String:(Int, MTLDataType)]) {
    
    guard let vertexFunction = device.defaultLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = device.defaultLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.rasterSampleCount = 1
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    do {
        var reflection:MTLAutoreleasedRenderPipelineReflection?
        let pipelineState = try device.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)
        
        var uniformLookupTable:[String:(Int, MTLDataType)] = [:]
        
        if let fragmentArguments = reflection?.fragmentArguments {
            for fragmentArgument in fragmentArguments where fragmentArgument.type == .buffer {
                if (fragmentArgument.bufferDataType == .struct) {
                    for (index, uniform) in fragmentArgument.bufferStructType!.members.enumerated() {
                        uniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        return (pipelineState, uniformLookupTable)
    } catch {
        fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
    }
}
