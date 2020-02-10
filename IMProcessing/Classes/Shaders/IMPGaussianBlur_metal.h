//
//  IMPGaussianBlur_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 14.01.16.
//  Copyright © 2016 Dehancer.photo. All rights reserved.
//

#ifndef IMPGaussianBlur_metal_h
#define IMPGaussianBlur_metal_h

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
    
    inline float3 gaussianSampledBlur(texture2d<float, access::sample> source,
                                      texture1d<float, access::read>   weights,
                                      texture1d<float, access::read>   offsets,
                                      float2 texCoord,
                                      float2 texelSize
                                      )
    {

        float3 color  = source.sample(baseSampler, texCoord).rgb * weights.read(uint(0)).x;
        
        for( uint i = 1; i < weights.get_width(); i++ ){
            
            float2 texCoordOffset =  texelSize * offsets.read(i).x;
            
            color += source.sample(baseSampler, (texCoord + texCoordOffset)).rgb * weights.read(i).x;
            color += source.sample(baseSampler, (texCoord - texCoordOffset)).rgb * weights.read(i).x;
            
        }
        
        return color;
    }
    
    kernel void kernel_gaussianSampledBlur(
                                           texture2d<float, access::sample> source       [[ texture(0) ]],
                                           texture2d<float, access::write>  destination  [[ texture(1) ]],
                                           texture1d<float, access::read>   weights      [[ texture(2) ]],
                                           texture1d<float, access::read>   offsets      [[ texture(3) ]],
                                           const device   float2           &texelSize    [[ buffer(0)  ]],
                                           uint2 gid [[thread_position_in_grid]]
                                           ) {

        float2 texCoord = float2(gid)/float2(source.get_width(),source.get_height());
        float3 color = gaussianSampledBlur(source,weights,offsets,texCoord,texelSize);
        destination.write(float4(color,1), gid);
    }
    
    
    fragment float4 fragment_gaussianSampledBlur(
                                                 IMPVertexOut in [[stage_in]],
                                                 texture2d<float, access::sample> source     [[ texture(0) ]],
                                                 texture1d<float, access::read>   weights    [[ texture(1) ]],
                                                 texture1d<float, access::read>   offsets    [[ texture(2) ]],
                                                 const device   float2           &texelSize  [[ buffer(0)  ]]
                                                 ) {
        float2 texCoord = in.texcoord.xy;
        float3 color =  gaussianSampledBlur(source,weights,offsets,texCoord,texelSize);
        return float4(color,1);
    }
    
    
    kernel void kernel_blendSource(texture2d<float, access::sample> source      [[texture(0)]],
                                   texture2d<float, access::write>  destination [[texture(1)]],
                                   texture2d<float, access::sample> background  [[texture(2)]],
                                   constant IMPAdjustment           &adjustment  [[buffer(0)]],
                                   uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = IMProcessing::sampledColor(background,destination,gid);
        float3 rgb     = IMProcessing::sampledColor(source,destination,gid).rgb;

        inColor = IMProcessing::blend(inColor, float4(rgb,1), adjustment.blending);
        destination.write(inColor, gid);
    }

    fragment float4 fragment_blendSource(
                                         IMPVertexOut in [[stage_in]],
                                         texture2d<float, access::sample> texture [[ texture(0) ]],
                                         texture2d<float, access::sample> source  [[ texture(1) ]],
                                         constant IMPAdjustment           &adjustment  [[buffer(0)]]
                                         
                                         ) {
        float4 inColor = source.sample(baseSampler, in.texcoord.xy);
        float3 rgb = texture.sample(baseSampler, in.texcoord.xy).rgb;

        inColor = IMProcessing::blend(inColor, float4(rgb,1), adjustment.blending);
        
        return  inColor;
    }

}

#endif

#endif

#endif /* IMPGaussianBlur_metal_h */
