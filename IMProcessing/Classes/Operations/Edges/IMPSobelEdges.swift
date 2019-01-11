//
//  IMPSobelEdges.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 25.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

public class IMPSobelEdges:IMPConvolution3x3{
    
    public static var Gx = float3x3([float3(-1, 0, 1),
                                     float3(-2, 0, 2),
                                     float3(-1, 0, 1)
        ])
    
    public static var Gy = float3x3([float3( 1,  2,  1),
                                     float3( 0,  0,  0),
                                     float3(-1, -2, -1)
        ])
    
    public override func kernels() -> [float3x3] {
        return [ IMPSobelEdges.Gx, IMPSobelEdges.Gy ]
    }
    
    required public init(context: IMPContext, name: String?=nil, functionName: String = "kernel_directionalSobelEdge") {
        super.init(context: context, name: name, functionName:functionName)
    }
    
    public required init(context: IMPContext, name: String?) {
        super.init(context: context, name: name, functionName:"kernel_directionalSobelEdge")
    }
}

public class IMPSobelEdgesGradient:IMPFilter{
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "SobelEdgesGradient")
        super.configure()
        add(filter: gDerivativeEdges)
        add(filter: sobelEdgesKernel)
    }
    private lazy var gDerivativeEdges:IMPGaussianDerivativeEdges = IMPGaussianDerivativeEdges(context: self.context)
    private lazy var sobelEdgesKernel:IMPSobelEdges = IMPSobelEdges(context: self.context, functionName:"kernel_sobelEdgesGradient")
}
