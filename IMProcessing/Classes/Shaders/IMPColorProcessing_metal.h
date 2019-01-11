//
//  IMPColorProcessing_metal.h
//  IMPCameraManager
//
//  Created by denis svinarchuk on 10.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//


#ifndef IMPColorProcessing_metal_h
#define IMPColorProcessing_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    kernel void kernel_luminance(texture2d<float, access::sample> inTexture [[texture(0)]],
                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = sampledColor(inTexture,outTexture,gid);
        inColor.rgb = dot(inColor.rgb, kIMP_Y_YUV_factor);
        outTexture.write(inColor, gid);
    }    
}

#endif

#endif

#endif /* IMPColorProcessing_metal_h */
