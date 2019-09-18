//
//  IMPCurvesFilter.swift
//  Pods
//
//  Created by Denis Svinarchuk on 28/06/2017.
//
//

//
//  IMPCurveFilter.swift
//  IMPCurveTest
//
//  Created by Denis Svinarchuk on 27/06/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Surge
import Accelerate

public class  IMPCurvesFilter: IMPFilter {
    
    public static let defaultAdjustment = IMPAdjustment( blending: IMPBlending(mode: .normal, opacity: 1))
    
    public var adjustment:IMPAdjustment = defaultAdjustment { didSet{ dirty = true } }
    public var colorSpace:IMPColorSpace = .rgb { didSet{  dirty = true } }
    
    public var master:IMPCurve? {
        didSet{
            if oldValue != master {
                
                func update(){
                    for (i,current) in self.channels.enumerated() {
                        if let c = current {
                            self.lut.channels[i] = self.matchMaster(c.values)
                        }
                    }
                }
                
                update()
                
                master?.addUpdateObserver(observer: { (curve) in
                    update()
                    self.dirty = true
                })
            }
            dirty = true
        }
    }
    
    public var channels:[IMPCurve?] = [IMPCurve?](repeating:nil, count:3) {
        didSet{
            for (i,c) in channels.enumerated() {
                if let hash = c {
                    curvesHash[hash] = i
                    self.lut.channels[i] = self.matchMaster(hash.values)                    
                }
                if  c != oldValue[i] {
                    c?.addUpdateObserver(observer: { (curve) in
                        if let key = self.curvesHash[curve] {
                            self.lut.channels[key] = self.matchMaster(curve.values)
                        }
                        self.dirty = true
                    })
                }
            }
            dirty = true
        }
    }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Curve Filter")
        super.configure()
        add(function: curvesKernel) { (source) in
            complete?(source)
        }
    }
    
    private var curvesHash = [IMPCurve:Int]()
    
    private func matchMaster(_ in_out:[Float]) -> [Float] {
        
        guard let values = master?.values else { return in_out }
        guard in_out.count > 0 else { return in_out }
        
        var diff = [Float](repeating: 0, count:in_out.count)
        var one:Float = 1
        let sz = vDSP_Length(in_out.count)
        
        vDSP_vsmsb(values, 1, &one, IMPLut1DTexture.identity, 1, &diff, 1, sz)
        vDSP_vsma(in_out, 1, &one, diff, 1, &diff, 1, sz)
        
        return diff
    }
    
    private lazy var lut:IMPLut1DTexture = IMPLut1DTexture(context: self.context)
    
    private lazy var curvesKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_adjustChannelCurves")
        f.optionsHandler = { (function, command, input, output) in
                                    
            command.setTexture(self.lut.texture, index:2)
            
            var cs = self.colorSpace.index
            command.setBytes(&cs,              length:MemoryLayout.stride(ofValue: cs),             index:0)
            command.setBytes(&self.adjustment, length:MemoryLayout.stride(ofValue: self.adjustment),index:1)
        }
        return f
    }()
    
}
