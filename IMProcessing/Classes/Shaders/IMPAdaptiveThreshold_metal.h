//
//  IMPAdaptiveThreshold_metal.h
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 31.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//


#ifndef IMPAdaptiveThreshold_metal_h
#define IMPAdaptiveThreshold_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

using namespace metal;

#ifdef __cplusplus

kernel void kernel_adaptiveThreshold(
                                     texture2d<float, access::sample> blurredInput  [[texture(0)]],
                                     texture2d<float, access::write>  destination   [[texture(1)]],
                                     texture2d<float, access::sample> luminnceInput [[texture(2)]],
                                     uint2 gid [[thread_position_in_grid]])
{
    float3 inColor   = IMProcessing::sampledColor(blurredInput,destination,gid).rgb;
    float3 lumColor  = IMProcessing::sampledColor(luminnceInput,destination,gid).rgb;
    float3 result(step(inColor - 0.05, lumColor));

    destination.write(float4(1-result,1), gid);
    //destination.write(float4(inColor,1),gid);
}

#endif

#endif

#endif /* IMPAdaptiveThreshold_metall_h */



