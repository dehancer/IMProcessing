//
//  IMPCurves_metal.h
//  Pods
//
//  Created by Denis Svinarchuk on 28/06/2017.
//
//

#ifndef IMPCurves_metal_h
#define IMPCurves_metal_h

#ifdef __METAL_VERSION__

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPSwift-Bridging-Metal.h"

inline float4 adjustChannelCurves(
                                  float4 inColor,
                                  texture1d_array<float, access::sample> curvesTexure,
                                  constant IMPColorSpaceIndex            &space,
                                  constant IMPAdjustment                 &adjustment
                                  )
{
    
    //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    float3 color = IMPConvertToNormalizedColor(IMPRgbSpace, space, inColor.rgb);
    
    float x = curvesTexure.sample(IMProcessing::baseSampler, color.x, 0).x;
    float y = curvesTexure.sample(IMProcessing::baseSampler, color.y, 1).x;
    float z = curvesTexure.sample(IMProcessing::baseSampler, color.z, 2).x;
    
    color = IMPConvertFromNormalizedColor(space, IMPRgbSpace, float3(x,y,z));
    
    float4 result = IMProcessing::blend(inColor, float4(color,1), adjustment.blending);
    
//    float4 result = float4(color, adjustment.blending.opacity);
//    
//    if (adjustment.blending.mode == IMPLuminosity)
//        result = IMProcessing::blendLuminosity(inColor, result);
//    else // only two modes yet
//        result = IMProcessing::blendNormal(inColor, result);
//    
    return result;
}

kernel void kernel_adjustChannelCurves(texture2d<float, access::sample>        inTexture    [[texture(0)]],
                                       texture2d<float, access::write>         outTexture   [[texture(1)]],
                                       texture1d_array<float, access::sample>  curvesTexure [[texture(2)]],
                                       constant IMPColorSpaceIndex             &space       [[buffer(0)]],
                                       constant IMPAdjustment                  &adjustment  [[buffer(1)]],
                                       uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    outTexture.write(adjustChannelCurves(inColor,curvesTexure,space,adjustment),gid);
}


#endif
#endif
#endif /* IMPCurves_metal_h */
