//
//  IMPConvolution_metal.h
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 27/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPConvolution_metal_h
#define IMPConvolution_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

using namespace metal;

#ifdef __cplusplus

kernel void kernel_convolutions3x3(
                                   texture2d<float, access::sample> source  [[texture(0)]],
                                   texture2d<float, access::write>  destination [[texture(1)]],
                                   const device float3x3 &kernelMatrix [[ buffer(0) ]],
                                   uint2 gid [[thread_position_in_grid]]
                                   )
{
    IMProcessing::Kernel3x3Colors corner(source,destination,gid,1);
    float3 color = corner.convolve(kernelMatrix);
    destination.write(float4(color,1),gid);
}


#endif

#endif

#endif /* IMPConvolution_metal_h */
