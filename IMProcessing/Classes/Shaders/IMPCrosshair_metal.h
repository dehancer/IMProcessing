//
//  IMPCrosshair_metal.h
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 09/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPCrosshair_metal_h
#define IMPCrosshair_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
    
    typedef struct {
        float4 position  [[position]];
        float  pointsize [[point_size]];
        float2 center;
        float  spacing;
    } IMPCrosshairVertexOut;
    
    
    vertex IMPCrosshairVertexOut vertex_crosshair(
                                                  const device IMPCorner     *vertex_array [[ buffer(0) ]],
                                                  const device float         &width        [[ buffer(1) ]],
                                                  unsigned int vid [[ vertex_id ]])
    {
        
        
        float2 position = vertex_array[vid].point;
        
        IMPCrosshairVertexOut out;
        out.position = float4(position.xy * float2(2.0,-2.0) - float2(1,-1), 0.0, 1.0);
        out.pointsize = width;
        
        out.spacing = 1.0 / width;
        out.center = float2(out.spacing * ceil(width / 2.0), out.spacing * ceil(width / 2.0));
        
        return out;
    }
    
    
    //
    // https://forums.developer.apple.com/thread/43570
    //
    fragment float4 fragment_line(IMPCrosshairVertexOut in [[stage_in]],
                                      texture2d<float, access::sample> texture    [[ texture(0) ]],
                                      const device float4              &color     [[ buffer(0) ]],
                                      float2 pointCoord  [[point_coord]])
    {
        if (length(pointCoord - float2(0.5)) > 0.5) {
            discard_fragment();
        }
        return color;
    }
    
    
    fragment float4 fragment_crosshair(
                                       IMPCrosshairVertexOut in [[stage_in]],
                                       texture2d<float, access::sample> texture    [[ texture(0) ]],
                                       const device float4              &color     [[ buffer(0) ]],
                                       float2 pointCoord  [[point_coord]]
                                       ) {
        
        float2 texcoord = pointCoord;
        float2 dist     = abs(in.center - texcoord);
        float  axisTest = step(in.spacing, texcoord.y) * step(dist.x, 0.09) + step(in.spacing, texcoord.x) * step(dist.y, 0.09);
        
        return float4(color.rgb * axisTest, axisTest);
    }
    
    fragment float4 fragment_blendTextureSource(
                                         IMPVertexOut in [[stage_in]],
                                         texture2d<float, access::sample> texture [[ texture(0) ]],
                                         texture2d<float, access::sample> source  [[ texture(1) ]],
                                         constant IMPAdjustment           &adjustment  [[buffer(0)]]
                                         
                                         ) {
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        
        float4 inColor = source.sample(baseSampler, in.texcoord.xy);
        float4 rgba = texture.sample(baseSampler, in.texcoord.xy);
        
        inColor = IMProcessing::blend(inColor, rgba, adjustment.blending);
        
        //if (adjustment.blending.mode == IMPLuminosity)
        //    inColor = IMProcessing::blendLuminosity(inColor, float4(rgba.rgb,adjustment.blending.opacity * rgba.a));
        //else // only two modes yet
        //    inColor = IMProcessing::blendNormal(inColor, float4(rgba.rgb, adjustment.blending.opacity * rgba.a ));
        
        return  inColor;
    }
}

#endif
    
#endif
    
#endif /* IMPCrosshair_metal_h */
