//
//  IMPCoreImage.metal
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 05.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#include <metal_stdlib>
#include "IMProcessing_metal.h"
using namespace metal;

kernel void kernel_EV(metal::texture2d<float, metal::access::sample> inTexture [[texture(0)]],
                       metal::texture2d<float, metal::access::write> outTexture [[texture(1)]],
                       constant float    &value [[buffer(0)]],
                       metal::uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    outTexture.write(inColor * pow(2 , value), gid);
}

kernel void kernel_red(metal::texture2d<float, metal::access::sample> inTexture [[texture(0)]],
                       metal::texture2d<float, metal::access::write> outTexture [[texture(1)]],
                       constant float    &value [[buffer(0)]],
                       metal::uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    inColor.rgb.r = inColor.rgb.r * 0;
    outTexture.write(inColor, gid);
}

kernel void kernel_green(metal::texture2d<float, metal::access::sample> inTexture [[texture(0)]],
                         metal::texture2d<float, metal::access::write> outTexture [[texture(1)]],
                         metal::uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
    inColor.rgb.g = 0.5;
    outTexture.write(inColor, gid);
}

