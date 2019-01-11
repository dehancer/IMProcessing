//
//  IMPWhiteBalance_metal.h
//  Pods
//
//  Created by denis svinarchuk on 06.09.17.
//
//

#ifndef IMPWhiteBalance_metal_h
#define IMPWhiteBalance_metal_h

#ifdef __METAL_VERSION__

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPSwift-Bridging-Metal.h"

kernel void kernel_adjustWhiteBalance(texture2d<float, access::sample>        inTexture    [[texture(0)]],
                                      texture2d<float, access::write>         outTexture   [[texture(1)]],
                                      constant float             &temperature [[buffer(0)]],
                                      constant float             &tint        [[buffer(1)]],
                                      constant IMPAdjustment     &adjustment  [[buffer(2)]],
                                      uint2 gid [[thread_position_in_grid]])
{   
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    
    float4 result(IMPadjustTempTint(float2(temperature,tint),inColor.rgb),1);
    
    result = IMProcessing::blend(inColor, result, adjustment.blending);
    
    outTexture.write(result,gid);
}


#endif
#endif
#endif /* IMPWhiteBalance_metal_h */
