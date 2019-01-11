//
//  IMPCChekerDetector_metal.h
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPCChekerDetector_metal_h
#define IMPCChekerDetector_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"


#ifdef __cplusplus

inline float3 getAvrgColor(int startx, int endx, int starty, int endy, uint2 gid,
                           texture2d<float>  source
                           ){
    float3 color(0);
    float3 c(0);
    
    for(int i = startx; i<endx; i++ ){
        for(int j = starty; j<endy; j++ ){
            uint2 gid2 = uint2(int2(gid)+int2(i,j));
            float3 s = source.read(gid2).rgb;
            color += s;
            c+=float3(1);
        }
    }
    
    return color/c;
}


kernel void kernel_patchScanner(
                                metal::texture2d<float, metal::access::sample> input [[texture(0)]],
                                metal::texture2d<float, metal::access::write>  destination [[texture(1)]],
                                metal::texture2d<float, metal::access::sample> source [[texture(2)]],
                                device    IMPCorner *corners  [[ buffer(0) ]],
                                uint2 tid [[thread_position_in_grid]]
                                )
{
    uint width  = destination.get_width();
    uint height = destination.get_height();
    float2 size = float2(width,height);
    
    IMPCorner corner = corners[tid.x];
    float2 point = corner.point;
    float4 slope = corner.slope;
    
    int regionSize = 64;
    int rs = -regionSize/2;
    int re =  regionSize/2+1;
    float2 shift = (float2(-slope.x,-slope.y) + float2(slope.z,slope.w)) / size;
    uint2 gid = uint2((float2(point.x,point.y) + 4 * shift) * size);
    
    float3 color  = getAvrgColor(rs * slope.x, re * slope.w,  rs * slope.y, re * slope.z, gid, source);
    corners[tid.x].color = float4(color,1);
}


kernel void kernel_patchColors(
                               metal::texture2d<float, metal::access::sample> source [[texture(0)]],
                               metal::texture2d<float, metal::access::write>  destination [[texture(1)]],
                               device    float2 *centers   [[ buffer(0) ]],
                               device    float3 *colors    [[ buffer(1) ]],
                               constant  float &regionSize [[ buffer(2) ]],
                               uint2 tid [[thread_position_in_grid]]
                               )
{
    uint width  = source.get_width();
    uint height = source.get_height();
    float2 size = float2(width,height);
    
    float2 point = centers[tid.x];
    
    int rs = -regionSize/2;
    int re =  regionSize/2+1;
    uint2 gid = uint2(float2(point.x,point.y) * size);
    
    colors[tid.x] =  getAvrgColor(rs, re,  rs, re, gid, source);
}



#endif // __cplusplus
#endif //__METAL_VERSION__
#endif // IMPCChekerDetector_metal

