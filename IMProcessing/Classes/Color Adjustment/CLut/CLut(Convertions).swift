//
//  CLut(Convertions).swift
//  Pods
//
//  Created by denis svinarchuk on 28.08.17.
//
//

import Foundation
import Metal
import simd


// MARK: - Convert from between types
public extension IMPCLut {        
    
    /// Convert the CLut object to another representation
    ///
    /// - Parameters:
    ///   - newType: new type `LutType`
    ///   - newLutSize: new lut size
    ///   - newFormat: new format `Format`
    ///   - newTitle: new title
    /// - Returns: IMPCLut
    /// - Throws: `FormatError`
    public func convert(to newType: LutType, lutSize newLutSize:Int? = nil, format newFormat: Format? = nil, title newTitle:String?=nil) throws -> IMPCLut {
        
        if newType == self._type && (self._lutSize == newLutSize &&  newLutSize != nil) {
            //
            // the same
            //
            return self
        }
        
        //
        // make new identity
        //
        
        let sz = newLutSize ?? _lutSize
//        if newType == .lut_2d && newLutSize == nil {
//            sz = _lutSize //Int(sqrt(Float(_lutSize*_lutSize*_lutSize)))/3; //sz = sz*sz*sz
//        }
        
        let lut = try IMPCLut(context: context,
                              lutType: newType,
                              lutSize: sz,
                              format: newFormat ?? _format,
                              compression: _compressionRange,
                              title: newTitle ?? _title)
        
        guard let newtext = lut.texture else { throw FormatError(file: "", line: 0, kind: .empty) }
        guard let text = texture else { throw FormatError(file: "", line: 0, kind: .empty) }

        var kernel:IMPFunction!
        var threads:MTLSize!
        var threadgroups:MTLSize!
        var level:uint? = nil

        if _type == .lut_3d && lut._type == .lut_2d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert3DLut_to_2DLut")
            threads = kernel.threadsPerThreadgroup
            threadgroups = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, 1)
        }

        else if _type == .lut_3d && lut._type == .lut_3d {
            kernel = IMPFunction(context: context, kernelName: "kernel_resample3DLut_to_3DLut")
            threads = MTLSizeMake(4, 4, 4)
            threadgroups  = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, newtext.depth/threads.depth)
        }
            
        else if _type == .lut_2d && lut._type == .lut_3d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert2DLut_to_3DLut")
            threads = MTLSizeMake(4, 4, 4)
            threadgroups  = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, newtext.depth/threads.depth)
            level = uint(sqrt(Float(_lutSize)))
        }

        else if _type == .lut_1d && lut._type == .lut_3d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert1DLut_to_3DLut")
            threads = MTLSizeMake(4, 4, 4)
            threadgroups  = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, newtext.depth/threads.depth)
        }

        else if _type == .lut_1d && lut._type == .lut_2d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert1DLut_to_2DLut")
            threads = kernel.threadsPerThreadgroup
            threadgroups = MTLSizeMake(newtext.width/threads.width, newtext.height/threads.height, 1)
        }

        else if _type == .lut_2d && lut._type == .lut_1d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert2DLut_to_1DLut")
            threads = MTLSizeMake(4, 1, 1)
            threadgroups = MTLSizeMake(newtext.width/threads.width, 1, 1)
            level = uint(sqrt(Float(_lutSize)))
        }

        else if _type == .lut_3d && lut._type == .lut_1d {
            kernel = IMPFunction(context: context, kernelName: "kernel_convert3DLut_to_1DLut")
            threads = MTLSizeMake(4, 1, 1)
            threadgroups = MTLSizeMake(newtext.width/threads.width, 1, 1)
        }
        
        else {
            throw FormatError(file: #file, line: #line, kind: .wrongType)
        }

        context.execute(.sync, wait: true){ (commandBuffer) in
            let commandEncoder =  kernel.commandEncoder(from: commandBuffer)
            commandEncoder.setTexture(text, index:0)
            commandEncoder.setTexture(newtext, index:1)
            commandEncoder.setTexture(newtext, index:2)
            if var l = level {
                commandEncoder.setBytes(&l,  length:MemoryLayout.stride(ofValue: l),  index:0)
            }
            commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup:threads)
            commandEncoder.endEncoding()
        }
        
        lut.texture = newtext
        
        return lut
    }
    
}
