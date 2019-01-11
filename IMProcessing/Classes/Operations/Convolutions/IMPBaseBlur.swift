//
//  IMPBaseBlur.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 31.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Accelerate
import simd

public class IMPBaseBlur: IMPFilter {
    
    public override var source: IMPImageProvider? {
        didSet{
            self.updateWeights()
        }
    }
    
    public static let radiusRange:(minimum:Float, maximum:Float) = (minimum:0.5, maximum:1000)
    
    public static let defaultAdjustment = IMPAdjustment(blending: IMPBlending(mode: .normal, opacity: 1))
    
    public var adjustment:IMPAdjustment!{
        didSet{
            adjustmentBuffer.copy(from: adjustment)
            update()
        }
    }
    
    public var radiusApproximation:Float = 8 {
        didSet{
            update()
        }
    }
    
    public var radius:Float = 0 {
        didSet{
            if radius < IMPGaussianBlur.radiusRange.minimum {
                radius = 0
            }
            else {
                radius = fmin(IMPGaussianBlur.radiusRange.maximum,
                              fmax(radius,
                                   IMPGaussianBlur.radiusRange.minimum))
            }
            update()
        }
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        
        super.configure()
        
        extendName(suffix: "GaussianBlur")
        radius = 0
        
        func fail(_ error:RegisteringError) {
            fatalError("IMPGaussianBlurFilter: error = \(error)")
            
        }
        
        if prefersRendering {
            add(shader: downscaleShader, fail: fail)
            add(shader: horizontalShader, fail: fail)
            add(shader: verticalShader, fail: fail)
            add(shader: upscaleShader, fail: fail){ (source) in
                complete?(source)
            }
            
        }
        else {
            add(function: downscaleKernel, fail: fail)
            add(function: horizontalKernel, fail: fail)
            add(function: verticalKernel, fail: fail)
            add(function: upscaleKernel, fail: fail){ (source) in
                complete?(source)
            }
            
        }
    }
    
    private var sigma:Float {
        get {
            return radiusApproximation > radius ? radius : radiusApproximation
        }
    }
    
    private var pixelRadius:Int {
        let samplingArea:Float = 1.0 / 256.0
        var newRadius:Int = 0
        if sigma >= 1.0 {
            newRadius = Int(floor(sqrt(-2.0 * pow(sigma, 2.0) * log(samplingArea * sqrt(2.0 * .pi * pow(sigma, 2.0))) )))
            newRadius += newRadius % 2
        }
        return newRadius
    }
    
    private var downsamplingFactor:Float {
        return  radiusApproximation > radius ? 1 : round(Float(radius)) / radiusApproximation
    }
    
    
    private lazy var adjustmentBuffer:MTLBuffer = self.context.makeBuffer(from: IMPBaseBlur.defaultAdjustment)
    
    private func update()  {
        self.updateWeights()
        super.dirty = true
    }
    
    private func updateWeights(){
        
        guard  let size = source?.size else {return}
        
        let newSize = NSSize(width: size.width/CGFloat(downsamplingFactor),
                             height: size.height/CGFloat(downsamplingFactor))
        
        if prefersRendering {
            downscaleShader.destinationSize = newSize
            upscaleShader.destinationSize = size
        }
        else {
            downscaleKernel.destinationSize = newSize
            upscaleKernel.destinationSize = size
        }
        
        var offsets:[Float] = [Float]()
        var weights:[Float] = [Float]()
        
        if radius > IMPGaussianBlur.radiusRange.minimum {
            var
            factor = float2(1/newSize.width.float, 0)
            memcpy(hTexelSizeBuffer.contents(), &factor, hTexelSizeBuffer.length)
            
            factor = float2(0, 1/newSize.height.float)
            memcpy(vTexelSizeBuffer.contents(), &factor, vTexelSizeBuffer.length)

            var extendedWeights:[Float]
            var extendedOffsets:[Float]
            
            (offsets, weights, extendedOffsets, extendedWeights) = optimized(pixelRadius, sigma: sigma)
            
            if extendedOffsets.count > 0 {
                for i in 0..<extendedWeights.count {
                    weights.append(extendedWeights[i])
                    offsets.append(extendedOffsets[i])
                }
            }
        }
        
        if weights.count == 0 {
            weights.append(1)
            offsets.append(1)
        }
        
        weightsTexture = context.device.texture1D(buffer:weights)
        offsetsTexture = context.device.texture1D(buffer:offsets)
    }
    
    
    lazy var hTexelSizeBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<float2>.size, options: [])!
    lazy var vTexelSizeBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<float2>.size, options: [])!
    lazy var weightsTexture:MTLTexture = {
        return self.context.device.texture1D(buffer:[Float](repeating:1, count:1))
    }()
    lazy var offsetsTexture:MTLTexture = {
        return self.context.device.texture1D(buffer:[Float](repeating:1, count:1))
    }()
    
    
    lazy var downscaleShader:IMPShader = IMPShader(context: self.context, name:"Blur Downscale Stage #1")
    
    lazy var upscaleShader:IMPShader   = {
        let s = IMPShader(context: self.context,
                          fragmentName: "fragment_blendSource", name:"Blur Upscale Stage #4")
        s.optionsHandler = { (shader,commandEncoder, input, output) in
            commandEncoder.setFragmentBuffer(self.adjustmentBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture(self.source?.texture, index:1)
        }
        return s
    }()
    
    lazy var downscaleKernel:IMPFunction = {
        let f = IMPFunction(context: self.context,
                            kernelName: "kernel_passthrough")
        return f
    }()
    
    lazy var upscaleKernel:IMPFunction = {
        let f = IMPFunction(context: self.context,
                            kernelName: "kernel_blendSource")
        
        f.optionsHandler = { (function,commandEncoder, input, output) in
            guard let texture = self.source?.texture else { return }
            commandEncoder.setBuffer(self.adjustmentBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(texture, index:2)
        }
        
        return f
    }()
    
    
    lazy var horizontalKernel:IMPFunction = {
        let f = IMPFunction(context: self.context,
                            kernelName: "kernel_gaussianSampledBlur")
        f.optionsHandler = { (function,commandEncoder, input, output) in
            
            commandEncoder.setBuffer(self.hTexelSizeBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(self.weightsTexture, index:2)
            commandEncoder.setTexture(self.offsetsTexture, index:3)
        }
        return f
    }()
    
    lazy var verticalKernel:IMPFunction = {
        let f = IMPFunction(context: self.context,
                            kernelName: "kernel_gaussianSampledBlur")
        f.optionsHandler = { (function,commandEncoder, input, output) in
            
            commandEncoder.setBuffer(self.vTexelSizeBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(self.weightsTexture, index:2)
            commandEncoder.setTexture(self.offsetsTexture, index:3)
        }
        return f
    }()
    
    lazy var horizontalShader:IMPShader = {
        let s = IMPShader(context: self.context,
                          fragmentName: "fragment_gaussianSampledBlur", name:"Blur Horizontal Stage #2")
        
        s.optionsHandler = { (shader,commandEncoder, input, output) in
            
            commandEncoder.setFragmentBuffer(self.hTexelSizeBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture(self.weightsTexture, index:1)
            commandEncoder.setFragmentTexture(self.offsetsTexture, index:2)
        }
        
        return s
    }()
    
    lazy var verticalShader:IMPShader = {
        
        let s = IMPShader(context: self.context,
                          fragmentName: "fragment_gaussianSampledBlur", name:"Blur Vertical Stage #3")
        
        s.optionsHandler = { (shader,commandEncoder, input, output) in
            
            commandEncoder.setFragmentBuffer(self.vTexelSizeBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture(self.weightsTexture, index:1)
            commandEncoder.setFragmentTexture(self.offsetsTexture, index:2)
        }
        
        return s
    }()
    
    open func weights(radius inPixels:Int, sigma:Float) -> [Float] {
        return [1]
    }
    
    func count(for radius: Int) -> (count:Int,trueCount:Int) {
        return (min(radius / 2 + (radius % 2), radiusApproximation.int-1), radius / 2 + (radius % 2))
    }
    
    func optimized(_ radius:Int, sigma:Float) -> (offsets:[Float],weights:[Float],extentedOffsets:[Float],extendedWeights:[Float]) {
        
        let standardWeights = weights(radius: radius, sigma:sigma)
        let (count, trueCount) = self.count(for: radius)
        
        var optimizedWeights = [Float]()
        optimizedWeights.append(standardWeights[0])
        
        var optimizedOffsets = [Float]()
        optimizedOffsets.append(0)
        
        for index in 0..<count {
            let firstWeight = standardWeights[Int(index * 2 + 1)]
            let secondWeight = standardWeights[Int(index * 2 + 2)]
            let optimizedWeight = firstWeight + secondWeight
            optimizedWeights.append(optimizedWeight)
            optimizedOffsets.append((firstWeight * (Float(index) * 2.0 + 1.0) + secondWeight * (Float(index) * 2.0 + 2.0)) / optimizedWeight)
        }
        
        var extendedOffsets = [Float]()
        var extendedWeights = [Float]()
        
        for index in count..<trueCount {
            let firstWeight = standardWeights[Int(index * 2 + 1)]
            let secondWeight = standardWeights[Int(index * 2 + 2)]
            
            let optimizedWeight = firstWeight + secondWeight
            let optimizedOffset = (firstWeight * (Float(index) * 2.0 + 1.0) + secondWeight * (Float(index) * 2.0 + 2.0)) / optimizedWeight
            
            extendedOffsets.append(optimizedOffset)
            extendedWeights.append(optimizedWeight)
        }
        
        return (optimizedOffsets,optimizedWeights, extendedOffsets, extendedWeights)
    }
}
