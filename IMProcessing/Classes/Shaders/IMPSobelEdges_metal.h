//
//  IMPSobelEdges_metal.h
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 25.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPSobelEdges_metal_h
#define IMPSobelEdges_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

using namespace metal;

#ifdef __cplusplus

#define THRESHOLD 1
#define EDGELSONLINE 5


kernel void kernel_directionalSobelEdge(
                                        texture2d<float, access::sample> source  [[texture(0)]],
                                        texture2d<float, access::write>  destination [[texture(1)]],
                                        const device float3x3 &Gx [[ buffer(0) ]],
                                        const device float3x3 &Gy [[ buffer(1) ]],
                                        uint2 gid [[thread_position_in_grid]]
                                        )
{
    
    IMProcessing::Kernel3x3Colors corner(source,destination,gid,1);
    
    float2 g(corner.convolveLuma(Gx),corner.convolveLuma(Gy));
    
    float  m = length(g);
    float2 d = normalize(g);
    
    // Offset by 1-sin(pi/8) to set to 0 if near axis, 1 if away
    d = sign(d) * floor(abs(d) + 0.617316);
    
    // Place -1.0 - 1.0 within 0 - 1.0
    d = (d + 1.0) * 0.5;
    
    destination.write( float4(m, d.x, d.y, 1.0),gid);
}

inline float3 sobelEdgeGradientIntensity(texture2d<float> source,
                                         texture2d<float, access::write>  destination,
                                         const device float3x3 &Gx [[ buffer(0) ]],
                                         const device float3x3 &Gy [[ buffer(1) ]],
                                         uint2 gid)
{
    
    IMProcessing::Kernel3x3Colors corner(source,destination,gid,1);
    
    float2 g(corner.convolveLuma(Gx),corner.convolveLuma(Gy));
    
    float2 slope = float2(g.y, g.x);
    
    if (length(slope)>0){
        slope = normalize(slope);
    }
    
    return float3(0, slope);
}


kernel void kernel_sobelEdgesGradient(
                                      texture2d<float, access::sample> derivative  [[texture(0)]],
                                      texture2d<float, access::write>  destination [[texture(1)]],
                                      const device float3x3 &Gx [[ buffer(0) ]],
                                      const device float3x3 &Gy [[ buffer(1) ]],
                                      uint2 gid [[thread_position_in_grid]]
                                      )
{
    float3 slope = sobelEdgeGradientIntensity(derivative, destination, Gx, Gy, gid);
    
    if (length(slope)>0 && (slope.y>=1 || slope.z>=1)){
        destination.write(float4(slope,1),gid);
    }
    else {
        destination.write(float4(float3(0),1),gid);
    }
}



//
// GPUImage2
//
//
// fragment float4 fragment_sobelEdge(
//                                   IMPVertexOut in [[stage_in]],
//                                   texture2d<float, access::sample> texture [[ texture(0) ]],
//                                   const device float &radius [[ buffer(0) ]]
//                                   ) {
//
//    IMProcessing::Kernel3x3Colors corner(texture,in.texcoord.xy,radius);
//
//    float x = -corner.top.leftLuma() - 2.0 * corner.top.centerLuma() - corner.top.rightLuma() + \
//    corner.bottom.leftLuma() + 2.0 * corner.bottom.centerLuma() + corner.bottom.rightLuma();
//
//    float y = -corner.bottom.leftLuma() - 2.0 * corner.mid.leftLuma() -  corner.top.leftLuma() + \
//    corner.bottom.rightLuma() + 2.0 * corner.mid.rightLuma() + corner.top.rightLuma();
//
//    float mag = length(float2(x, y)) * 1;
//
//    return float4(float3(mag),1);
//}

#endif // __cplusplus
#endif // __METAL_VERSION__
#endif // IMPSobelEdges_metal_h

