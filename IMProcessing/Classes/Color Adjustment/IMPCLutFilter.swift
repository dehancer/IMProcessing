//
//  IMPCLutFilter.swift
//  Pods
//
//  Created by denis svinarchuk on 29.08.17.
//
//

import Foundation


/// Color LUT filter 
public class IMPCLutFilter: IMPFilter {
    
    
    /// Default adjustment
    public static let defaultAdjustment = IMPAdjustment( blending: IMPBlending(mode: .normal, opacity: 1))
    
    /// Current addjustment
    public var adjustment:IMPAdjustment = defaultAdjustment { didSet{ dirty = true } }
    
    
    /// Color LUT is nil by default. Application of the filter is no effect in this case.    
    public var clut:IMPCLut? {
        willSet{
            clut?.removeObserver(updated: clutUpdateHandler)
        }
        didSet{
            guard oldValue !== clut else {    
                dirty = true
                return 
            }
                     
            if let o = oldValue?.observers{
                clut?.observers = o
            }
            oldValue?.removeAllObservers()
            
            if let kernel = currentKernel {
                remove(function: kernel)
            }
            
            if let lut =  clut {
                switch lut.type {
                case .lut_1d:
                    currentKernel = kernel1D
                case .lut_2d:
                    currentKernel = kernel2D
                case .lut_3d:
                    currentKernel = kernel3D
                }
            }
            if let kernel = currentKernel {
                insert(function: kernel, at: 0) { [weak self] imp in
                    guard let self = self else { return }
                    self.completeHandler?(imp)
                }
                dirty = true
            }
            
            clut?.addObserver(updated: clutUpdateHandler)
        }
    }
 
    deinit {
        clut?.removeObserver(updated: clutUpdateHandler)
    }
    
    private lazy var clutUpdateHandler:IMPCLut.UpdateHandler = {
        let handler:IMPCLut.UpdateHandler = { lut in
            self.dirty = true
        }
        return handler
    }() 
    
    /// Create color LUT filtering with 2d color LUT
    ///
    /// - Parameters:
    ///   - context: filtering context    
    ///   - lutSize: 3D lut size
    ///   - format: precision format .integer or .float
    ///   - title: lut title
    public convenience init(context: IMPContext, lutSize:Int, format:IMPCLut.Format, title:String? = nil) {
        self.init(context: context, name: title)
        defer {
            do {
                clut = try IMPCLut(context: context, lutType: .lut_2d, lutSize: lutSize, format: format, title: title)
            }
            catch let error {
                fatalError("IMPCLutFilter Error: \(error)")
            }
        }
    }
       
    public override func configure(complete: IMPFilterProtocol.CompleteHandler?) {
        completeHandler = complete
        extendName(suffix: "LutFilter")
        
        super.configure()
        
        func optionsHandler(_ function:IMPFunction, 
                            _ command:MTLComputeCommandEncoder, 
                            _ inputTexture:MTLTexture?, 
                            _ outputTexture:MTLTexture?){
                                    
            guard let lut = self.clut else { return }
            
            command.setTexture(lut.texture, index:2)
                        
            command.setBytes(&self.adjustment, length:MemoryLayout.stride(ofValue: self.adjustment),index:0)
            if lut.type == .lut_2d {
                var level = lut.level 
                command.setBytes(&level,              length:MemoryLayout.stride(ofValue: level),       index:1)
            }
        }
        
        kernel1D.optionsHandler = optionsHandler
        kernel2D.optionsHandler = optionsHandler
        kernel3D.optionsHandler = optionsHandler                            
    }
    
    private lazy var kernel1D:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_adjustLutD1D")    
    private lazy var kernel2D:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_adjustLutD2D")
    private lazy var kernel3D:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_adjustLutD3D")
    
    private var currentKernel:IMPFunction?  
    private var completeHandler:IMPFilterProtocol.CompleteHandler?
}
