//
//  IMPVignette_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 15.06.16.
//  Copyright © 2016 Dehancer.photo. All rights reserved.
//

#ifndef IMPVignette_metal_h
#define IMPVignette_metal_h

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
    
    kernel void kernel_vignetteCenter(
                                      texture2d<float, access::sample>   inTexture  [[texture(0)]],
                                      texture2d<float, access::write>   outTexture  [[texture(1)]],
                                      constant IMPAdjustment           &adjustment  [[buffer(0)]],
                                      constant float                        &start  [[buffer(1)]],
                                      constant float                          &end  [[buffer(2)]],
                                      constant float3                       &color  [[buffer(3)]],
                                      constant float2                      &center  [[buffer(4)]],
                                      uint2 gid [[thread_position_in_grid]]
                                      )
    {
        float4 inColor = IMProcessing::sampledColor(inTexture, outTexture, gid);
        
        
        float w = float(inTexture.get_width());
        float h = float(inTexture.get_height());
        
        float2 coords  = float2(gid) * float2(1.0/w,1.0/h);
        
        float d = distance(coords,center);
        
        float  percent = smoothstep(start, end, d);
        float3 rgb     = mix(inColor.rgb, color, percent);
        //float4 result  = float4(rgb,inColor.a);

        float4 result = IMProcessing::blend(inColor,  float4(rgb,inColor.a), adjustment.blending);

//        if (adjustment.blending.mode == IMPLuminosity)
//            result = IMProcessing::blendLuminosity(inColor, float4(rgb,adjustment.blending.opacity));
//        else // only two modes yet
//            result = IMProcessing::blendNormal(inColor, float4(rgb,adjustment.blending.opacity));
        
        outTexture.write(result,gid);
    }
    
    kernel void kernel_vignetteFrame(
                                     texture2d<float, access::sample>   inTexture  [[texture(0)]],
                                     texture2d<float, access::write>   outTexture  [[texture(1)]],
                                     constant IMPAdjustment           &adjustment  [[buffer(0)]],
                                     constant float                        &start  [[buffer(1)]],
                                     constant float                          &end  [[buffer(2)]],
                                     constant float3                       &color  [[buffer(3)]],
                                     constant IMPRegion                 &regionIn  [[buffer(4)]],
                                     uint2 gid [[thread_position_in_grid]]
                                     )
    {
        float4 inColor = IMProcessing::sampledColor(inTexture, outTexture, gid);
        
        
        float w = float(inTexture.get_width());
        float h = float(inTexture.get_height());
        
        float2 coords  = float2(gid) * float2(1.0/w,1.0/h);
        
        float d = 0;
        
        float2 lb(regionIn.left,1-regionIn.bottom);
        
        float2 lt(regionIn.left,regionIn.top);
        float2 rt(1-regionIn.right,regionIn.top);
        float2 rb(1-regionIn.right,1-regionIn.bottom);
        
        if (coords.x<=regionIn.left){
            if (coords.y>=1-regionIn.bottom){
                d =  distance(coords,lb);
            }
            else if (coords.y<=regionIn.top) {
                d =  distance(coords,lt);
            }
            else {
                d = distance(float2(coords.x,0),float2(regionIn.left,0));
            }
        }
        else if (coords.x>=1-regionIn.right){
            if (coords.y>=1-regionIn.bottom){
                d =  distance(coords,rb);
            }
            else if (coords.y<=regionIn.top) {
                d =  distance(coords,rt);
            }
            else {
                d = (regionIn.right-(1-coords.x));
            }
        }
        else if (coords.y<=regionIn.top){
            d = (regionIn.top-coords.y);
        }
        else if (coords.y>=1-regionIn.bottom){
            d = (regionIn.bottom-(1-coords.y));
        }
        
        float  percent = smoothstep(start, end, d);
        float3 rgb     = mix(inColor.rgb, color, percent);
        //float4 result  = float4(rgb,1);
        
        float4 result = IMProcessing::blend(inColor,  float4(rgb,1), adjustment.blending);

//        if (adjustment.blending.mode == IMPLuminosity)
//            result = IMProcessing::blendLuminosity(inColor, float4(rgb,adjustment.blending.opacity));
//        else // only two modes yet
//            result = IMProcessing::blendNormal(inColor, float4(rgb,adjustment.blending.opacity));
        
        outTexture.write(result,gid);
    }
    
}

#endif

#endif

#endif /* IMPVignette_metal_h */
