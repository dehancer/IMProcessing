//
//  IMPContrastScretching_metal.h
//  Pods
//
//  Created by denis svinarchuk on 11.09.17.
//
//

#ifndef IMPContrastScretching_metal_h
#define IMPContrastScretching_metal_h

#ifdef __METAL_VERSION__

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPSwift-Bridging-Metal.h"

inline float4 adjustContrastStretching(float4 inColor, constant IMPContrastAdjustment &adjustment){
    float4 result = inColor;
    
    float3 alow  = float4(adjustment.minimum).rgb;
    float3 ahigh = float4(adjustment.maximum).rgb;
    
    result.rgb  = clamp((result.rgb - alow)/(ahigh-alow), float3(0.0), float3(1.0));
    
    result = IMProcessing::blend(inColor, result, adjustment.blending); 

//    if (adjustment.blending.mode == IMPLuminosity) {
//        result = IMProcessing::blendLuminosity(inColor, float4(result.rgb, adjustment.blending.opacity));
//    }
//    else {// only two modes yet
//        result = IMProcessing::blendNormal(inColor, float4(result.rgb, adjustment.blending.opacity));
//    }
    
    return result;
}

kernel void kernel_adjustContrastStretching(
                                            texture2d<float, access::sample>   inTexture   [[texture(0)]],
                                            texture2d<float, access::write>    outTexture  [[texture(1)]],
                                            constant IMPContrastAdjustment     &adjustment [[buffer(0)]],
                                            uint2 gid [[thread_position_in_grid]]){
    
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustContrastStretching(inColor,adjustment),gid);
}



#endif
#endif
#endif /* IMPContrastScretching_metal_h */
