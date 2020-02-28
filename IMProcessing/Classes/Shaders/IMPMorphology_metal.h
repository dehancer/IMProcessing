//
//  IMPMorpho;ogy_metal.h
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 22/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPMorphology_metal_h
#define IMPMorphology_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

#ifdef __cplusplus


kernel void kernel_erosion(texture2d<float, access::sample> source      [[texture(0)]],
                           texture2d<float, access::write>  destination [[texture(1)]],
                           constant float2                 &texelSize   [[buffer(0)]],
                           constant uint                   &dimensions  [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]]){
    
    float3 center = IMProcessing::sampledColor(source,destination,gid).rgb;
    
    float2 texCoord = float2(gid)/float2(source.get_width(),source.get_height());
    
    float3 minv = center;
    
    for(uint x = 1; x<dimensions/2; x+=1){
        
        float3 colorNeg = source.sample(IMProcessing::baseSampler, (texCoord - texelSize * float2(x))).rgb;
        
        minv = min(colorNeg,minv);
        
        float3 colorPos = source.sample(IMProcessing::baseSampler, (texCoord + texelSize * float2(x))).rgb;

        minv = min(colorPos,minv);

    }
    
    destination.write(float4(minv,1), gid);
}


kernel void kernel_dilation(texture2d<float, access::sample> source     [[texture(0)]],
                           texture2d<float, access::write>  destination [[texture(1)]],
                           constant float2                 &texelSize   [[buffer(0)]],
                           constant uint                   &dimensions  [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    float3 center = IMProcessing::sampledColor(source,destination,gid).rgb;
    
    float2 texCoord = float2(gid)/float2(destination.get_width(),destination.get_height());
    
    float3 maxv = center;
    
    for(uint x = 1; x<dimensions/2; x+=1){
        
        float3 colorNeg = source.sample(IMProcessing::baseSampler, (texCoord - texelSize * float2(x))).rgb;
        
        maxv = max(colorNeg,maxv);
        
        float3 colorPos = source.sample(IMProcessing::baseSampler, (texCoord + texelSize * float2(x))).rgb;
        
        maxv = max(colorPos,maxv);
        
    }
    
    destination.write(float4(maxv,1), gid);
}



#endif // __cplusplus
#endif //__METAL_VERSION__
#endif /*IMPMorphology_metal_h*/


