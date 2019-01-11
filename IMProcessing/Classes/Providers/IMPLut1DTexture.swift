//
//  IMPLut1DTexture.swift
//  Pods
//
//  Created by Denis Svinarchuk on 28/06/2017.
//
//

//import IMProcessing
import Surge

public class IMPLut1DTexture: IMPTextureProvider, IMPContextProvider {
    
    public static let identity:[Float] =  {         
        return getIdentity()
    }()
    
    public lazy var texture:MTLTexture? = self.context.device.texture1DArray(buffers: self.channels)
    public var context:IMPContext
    
    public var channels = [IMPLut1DTexture.getIdentity(),IMPLut1DTexture.getIdentity(),IMPLut1DTexture.getIdentity()] {
        didSet{
            update(channels: channels)
        }
    }
    
    private static func getIdentity() -> [Float] {
        return Surge.linspace(Float(0), Float(1), num: kIMPCurveCollectionResolution)
    }
    
    public init(context: IMPContext, channels:[[Float]]? = nil) {
        self.context = context
        defer {
            if let cs = channels {
                self.channels = cs
            }
        }
    }
    
    public func update(channels:[[Float]]){
        if texture == nil {
            texture = context.device.texture1DArray(buffers: channels)
        }
        else {
            texture?.update1DArray(channels)
        }
    }    
}


public extension IMPLut1DTexture {
    public func convert(to newType: IMPCLut.LutType, lutSize newLutSize:Int, format newFormat: IMPCLut.Format = .float, title newTitle:String?=nil) throws -> IMPCLut {
        
        let lut = try IMPCLut(context: context, lutType: newType, lutSize: newLutSize, format: newFormat, compression: float2(0,1), title: newTitle)
        
        guard let newtext = lut.texture else { throw IMPCLut.FormatError(file: "", line: 0, kind: .empty) }
        guard let text = texture else { throw IMPCLut.FormatError(file: "", line: 0, kind: .empty) }
        
        var kernel:IMPFunction!
        var threads:MTLSize!
        var threadgroups:MTLSize!
        
        if lut._type == .lut_1d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert1DArrayLut_to_1DLut")
            threads = MTLSizeMake(4, 1, 1)
            threadgroups = MTLSizeMake(newtext.width/threads.width, 1, 1)
        }
            
        else if lut._type == .lut_2d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert1DArrayLut_to_2DLut")
            threads = kernel.threadsPerThreadgroup
            threadgroups = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, 1)
        }
            
        else if lut._type == .lut_3d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert1DArrayLut_to_3DLut")
            threads = MTLSizeMake(4, 4, 4)
            threadgroups  = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, newtext.depth/threads.depth)
        }
        
        context.execute(.sync, wait: true){ (commandBuffer) in
            let commandEncoder =  kernel.commandEncoder(from: commandBuffer)
            commandEncoder.setTexture(text, index:0)
            commandEncoder.setTexture(newtext, index:1)
            commandEncoder.setTexture(newtext, index:2)
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threads)
            commandEncoder.endEncoding()
        }
        
        lut.texture = newtext
        
        return lut        
    }
}
