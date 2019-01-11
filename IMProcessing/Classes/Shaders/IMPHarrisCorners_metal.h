//
//  IMPHarrisCorners_metal.h
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 27/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPHarrisCorners_metal_h
#define IMPHarrisCorners_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"


#ifdef __cplusplus

fragment float4 fragment_harrisCorner(
                                      IMPVertexOut in [[stage_in]],
                                      texture2d<float, access::sample> texture [[ texture(0) ]],
                                      const device float &sensitivity [[ buffer(0)  ]]
                                      ) {
    constexpr float k = 0.04;
    
    // (Ix^2,Iy^2)
    float3 I2 = texture.sample(IMProcessing::cornerSampler, in.texcoord.xy).rgb;
    
    float I2S = I2.x + I2.y;
    
    float Ixy2 = (I2.z * 2.0) - 1.0;
    
    // R = Ix^2 * Iy^2 - Ixy * Ixy - k * (Ix^2 + Iy^2)^2
    float cornerness = I2.x * I2.y - Ixy2 * Ixy2 - k * I2S * I2S;
    
    return float4(float3(cornerness * sensitivity), 1.0);
}


#endif // __cplusplus
#endif //__METAL_VERSION__
#endif // IMPHarisCorrners_metal

