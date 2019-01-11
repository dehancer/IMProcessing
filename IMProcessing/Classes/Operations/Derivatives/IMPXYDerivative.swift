//
//  IMPXYDerivative.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPXYDerivative: IMPDerivative {
    public required init(context: IMPContext, name: String?=nil) {
        super.init(context:context, name:name, functionName:"fragment_xyDerivative")
    }
    
    public required init(context: IMPContext, name: String?, functionName: String) {
        fatalError("IMPXYDerivative:init(context:name:functionName:) has been already implemented")
    }
    
    public override func configure(complete:CompleteHandler?=nil) {
        extendName(suffix: "XY")
        super.configure(complete: complete)
    }
}
