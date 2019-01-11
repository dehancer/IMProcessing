//
//  IMPCLutTpsTransform.swift
//  CryptoSwift
//
//  Created by denn on 15.08.2018.
//

import Foundation

public class IMPTpsCLutFilter: IMPTpsFilter {
    
    public var cLut:IMPCLut!
    
    override public func configure(complete: IMPFilter.CompleteHandler?) {
        
        super.extendName(suffix: "TPS Lut Transform")
        super.configure(complete: complete)
        source = identityLut
        cLut =  try! IMPCLut(context: context, lutType: .lut_2d, lutSize: 64, format: .float)
        
        addObserver(destinationUpdated: { image in
            do {
                try self.cLut.update(from: image)
            }
            catch let error {
                Swift.print("IMPTpsLutTransform error: \(error)")
            }
        })
    }
    
    private lazy var identityLut:IMPCLut =
        try! IMPCLut(context: context, lutType: .lut_2d, lutSize: 64, format: .float)
}
