//
//  IMPStdlib_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//


#ifndef IMProcessingUI_metal 
#define IMProcessingUI_metal

#ifdef __METAL_VERSION__

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

//#include "IMProcessing_metal.h"

/**
 * View rendering vertex
 */
vertex VertexOut vertex_passview(
                                 device VertexIn*   verticies [[ buffer(0) ]],
                                 unsigned int        vid       [[ vertex_id ]]
                                 ) {
    VertexOut out;
    
    device VertexIn& v = verticies[vid];
    
    float3 position = float3(float2(v.position) , 0.0);
    
    out.position = float4(position, 1.0);    
    out.texcoord = float2(v.texcoord);
    
    return out;
}

/**
 *  Pass through fragment
 *
 */
fragment float4 fragment_passview(
                                  VertexOut in [[ stage_in ]],
                                  texture2d<float, access::sample> texture [[ texture(0) ]]
                                  ) {
    float3 rgb = texture.sample(IMProcessing::baseSampler, in.texcoord).rgb;
    return float4(rgb, 1.0);
}

fragment float4 fragment_placeHolderView(
                                  VertexOut in [[ stage_in ]],
                                  constant float4 &color [[ buffer(0) ]]
                                  ) {
    return color;
}

kernel void kernel_view(metal::texture2d<float, metal::access::sample> inTexture [[texture(0)]],
                        metal::texture2d<float, metal::access::write> outTexture [[texture(1)]],
                        metal::uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    outTexture.write(inColor, gid);
}


#endif

#endif /*IMProcessingUI_metal*/
