//
//  IMPPosterize_metal.h
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 23/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPPosterize_metal_h
#define IMPPosterize_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    kernel void kernel_posterize(
                                      texture2d<float, access::sample>   inTexture  [[texture(0)]],
                                      texture2d<float, access::write>   outTexture  [[texture(1)]],
                                      constant float                    &levels      [[buffer(0)]],
                                      uint2 gid [[thread_position_in_grid]]
                                      ) {
        float4 inColor = IMProcessing::sampledColor(inTexture, outTexture, gid);
    
        float3 result = floor((inColor.rgb * levels) + float3(0.5)) / levels;
    
        outTexture.write(float4(result,1),gid);
    }
    
}

#endif

#endif

#endif /* IMPPosterize_metal_h */
