//
//  IMPTpsTransform_metal.h
//  CryptoSwift
//
//  Created by denn on 13.08.2018.
//

#ifndef IMPTpsTransform_metal_h
#define IMPTpsTransform_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPConstants_metal.h"
#include "IMPMatrixExtension.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    inline float4 color_plane(float2 xy, float3 reference, IMPColorSpaceIndex space, uint2  spacePlanes, bool drawClipping) {
        
        float2 xrange = IMPgetColorSpaceRange (space, spacePlanes.x);
        float2 yrange = IMPgetColorSpaceRange (space, spacePlanes.y);
        
        float3 nc = reference;
        
        nc[spacePlanes.x] = xy.x * (xrange.y - xrange.x) + xrange.x;
        nc[spacePlanes.y] = xy.y * (yrange.y - yrange.x) + yrange.x;
        
        nc = IMPConvertColor(space, IMPRgbSpace, nc);
        
        float4 result = float4(nc,1);
        float  a = 1;
        
        if (drawClipping){
            for(int i=0; i<3; i++){
                if (result[i]<0 || result[i]>1) {
                    a = 0.2;
                    break;
                }
            }
        }
        
        return mix(float4(0.2,0.2,0.2,1),result,float4(a));
    }
    
    kernel void kernel_tpsPlaneTransform(
                                         metal::texture2d<float, metal::access::sample> source     [[texture(0)]],
                                         metal::texture2d<float, metal::access::write>  outTexture [[texture(1)]],
                                         constant float3              &reference      [[buffer(0)]],
                                         constant IMPColorSpaceIndex  &space          [[buffer(1)]],
                                         constant uint2               &spacePlanes    [[buffer(2)]],
                                         
                                         constant float3  *weights     [[buffer(3)]],
                                         constant float3  *q           [[buffer(4)]],
                                         constant int     &count       [[buffer(5)]],
                                         
                                         metal::uint2 gid [[thread_position_in_grid]]
                                         )
    {
        float2 xy = float2(gid)/float2(outTexture.get_width(),outTexture.get_height());
        
        float3 xyz;
        
        xyz[spacePlanes.x] = xy.x;
        xyz[spacePlanes.y] = xy.y;
        
        xyz = IMProcessing::tpsValue<float3,float,3>(xyz, weights, q, count);
        
        xy.x = xyz[spacePlanes.x];
        xy.y = xyz[spacePlanes.y];
        
        float4 rgba = color_plane(xy, reference, space, spacePlanes, false);
        
        outTexture.write(rgba, gid);
    }
    
    kernel void kernel_tpsLutTransform(
                                       metal::texture2d<float, metal::access::read> source [[texture(0)]],
                                       metal::texture2d<float, metal::access::write>  outTexture [[texture(1)]],
                                       constant IMPColorSpaceIndex  &space          [[buffer(0)]],
                                       
                                       constant float3  *weights     [[buffer(1)]],
                                       constant float3  *q           [[buffer(2)]],
                                       constant int     &count       [[buffer(3)]],
                                       constant IMPAdjustment  &adjustment   [[buffer(4)]],
                                       constant float3  &levels      [[buffer(5)]],

                                       metal::uint2 gid [[thread_position_in_grid]]
                                       )
    {
        
        float3 rgb = source.read(gid).rgb;
        
        float3 lutXyz = IMPConvertToNormalizedColor(IMPRgbSpace,
                                                    space,
                                                    rgb);
        
        float3 sources_lutXyz = lutXyz;
        
        lutXyz = IMProcessing::tpsValue<float3,float,3>(lutXyz, weights, q, count);
        
        lutXyz = mix(sources_lutXyz,lutXyz,levels);

        float3 lutRgb = IMPConvertFromNormalizedColor(space,
                                                      IMPRgbSpace,
                                                      lutXyz);
                
        float4 result = IMProcessing::blend(float4(rgb,1), float4(lutRgb,1), adjustment.blending);

        outTexture.write(result, gid);
    }
    
}

#endif //__cplusplus

#endif //__METAL_VERSION__

#endif //IMPTpsTransform_metal_h
