//
//  IMPResampler.swift
//  IMPCameraManager
//
//  Created by denis svinarchuk on 11.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal
import Accelerate

open class IMPResampler: IMPFilter{
    
    public var maxSize:CGFloat? {
        didSet{
            if maxSize == nil {
                remove(filter:resampler)
            } else {
                insert(filter: resampler, at: 0)
//                { (source) in
//                    self.complete?(source)
//                }
            }
            updateResampler()
            dirty = true
        }
    }
    
    private func updateResampler(){
        //resampler.flush()
        if let size = source?.size,
            let maxSize = self.maxSize {
            let scale = fmax(fmin(fmin(maxSize/size.width, maxSize/size.height),1),0.01)
            destinationSize = NSSize(width: size.width * scale, height: size.height * scale);
        }
    }
    
    public override var destinationSize: NSSize? {
        didSet{
            resampler.destinationSize = destinationSize // NSSize(width: size.width * scale, height: size.height * scale)
        }
    }
    
    
    open override func configure(complete:CompleteHandler?=nil) {
        //self.complete = complete
        extendName(suffix: "Resampler")
        super.configure() { (source) in
            complete?(source)
        }
        
        addObserver(newSource: { (source) in
            self.updateResampler()
        })        
    }
    
    private lazy var resampleShader:IMPShader = IMPShader(context: self.context)
    private lazy var resampler:IMPCIFilter = { return IMPCoreImageMTLShader.register(shader: self.resampleShader)}()
}

public extension IMPResampler{
    public convenience init(context: IMPContext,  maxSize:CGFloat?) {
        self.init(context: context)
        defer {
            self.maxSize = maxSize
        }
    }
}
