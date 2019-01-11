//
//  IMPHarrisCorrnersDetector_metal.h
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 26.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPHarrisCornersDetector_metal_h
#define IMPHarrisCornersDetector_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"


#ifdef __cplusplus


inline float2 getSlops(int startx, int endx, int starty, int endy, uint2 gid,
                       texture2d<float>  derivative,
                       texture2d<float, access::write>  destination ){
    
    float2 slops = float2(0);
    
    for(int i = startx; i<endx; i++ ){
        for(int j = starty; j<endy; j++ ){
            uint2 gid2 = uint2(int2(gid)+int2(i,j));
            float2 s = derivative.read(gid2).xy;
            slops += s;
        }
    }
    
    return slops.yx;
}

kernel void kernel_pointsScanner(
                                 texture2d<float, access::sample> suppression      [[texture(0)]],
                                 texture2d<float, access::write>  destination      [[texture(1)]],
                                 texture2d<float, access::sample>  derivative      [[texture(2)]],
                                 
                                 device   IMPCorner      *corners   [[ buffer(0) ]],
                                 device   atomic_uint    *count     [[ buffer(1) ]],
                                 constant uint           &pointsMax [[ buffer(2) ]],
                                 
                                 uint2 groupId   [[threadgroup_position_in_grid]],
                                 uint2 gridSize  [[threadgroups_per_grid]],
                                 uint2 pid [[thread_position_in_grid]]
                                 )
{
    uint width  = derivative.get_width();
    uint height = derivative.get_height();
    
    uint gw = (width+gridSize.x-1)/gridSize.x;
    uint gh = (height+gridSize.y-1)/gridSize.y;
    
    
    int regionSize = 24;
    int rs = -regionSize/2;
    int re = regionSize/2+1;
    
    for (uint y=0; y<gh; y+=1){
        
        uint ry = y + groupId.y * gh;
        if (ry > height) break;
        
        for (uint x=0; x<gw; x+=1){

            uint rx = x + groupId.x * gw;
            if (rx > width) break;
            
            uint2 gid(rx,ry);

            float3 color = suppression.read(gid).rgb;

            //destination.write(derivative.read(gid),gid);

            if (color.g > 0) {

                uint index = atomic_fetch_add_explicit(count, 1, memory_order_relaxed);
                if (index > pointsMax) {
                    return;
                }

                IMPCorner corner;
                corner.point = float2(gid)/float2(width,height);
                corner.slope = float4(0);
                
                corner.slope.x  = getSlops(rs, 0,  rs, re,  gid, derivative,destination).x;
                corner.slope.y  = getSlops(rs, re, rs, 0,   gid, derivative,destination).y;
                corner.slope.z  = getSlops(rs, re, 0,  re,  gid, derivative,destination).y;
                corner.slope.w  = getSlops(0,  re, rs, re,  gid, derivative,destination).x;
                
                if (length(corner.slope)){
                    corner.slope = normalize(corner.slope);
                }

                corners[index] = corner;
            }
        }
    }
}
#endif // __cplusplus
#endif //__METAL_VERSION__
#endif // IMPHarisCorrnersDetector_metal

