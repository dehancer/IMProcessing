    //
    //  IMPAdjustmentWB_metal.h
    //  IMProcessing
    //
    //  Created by denis svinarchuk on 12.01.16.
    //  Copyright © 2016 Dehancer.photo. All rights reserved.
    //

#ifndef IMPAdjustmentWB_metal_h
#define IMPAdjustmentWB_metal_h

    //#ifdef __METAL_VERSION__
    //
    //#include "IMPSwift-Bridging-Metal.h"
    //#include "IMPFlowControl_metal.h"
    //#include "IMPCommon_metal.h"
    //#include "IMPColorSpaces_metal.h"
    //#include "IMPBlending_metal.h"
    //
    //using namespace metal;

#ifdef __METAL_VERSION__

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPSwift-Bridging-Metal.h"
#include "IMPBlending_metal.h"

namespace IMProcessing
    {
    /**
     * White balance adjustment
     * The main idea has been taken from http://zhur74.livejournal.com/44023.html
     */
    
    inline float4 adjustGray(float4 inColor,
                             constant float3& dominantColor,
                             constant IMPAdjustment &adjustment,
                             bool          compensateBlue
                             ) {
        
        float4 invert_color = float4((1.0 - dominantColor), 1.0);
        
        constexpr float4 grey128 = float4(0.5,    0.5, 0.5,      1.0);
        
        invert_color             = blendLuminosity(invert_color, grey128); // compensate brightness
        
        if (compensateBlue) {
            constexpr float4 grey130 = float4(0.5098, 0.5, 0.470588, 1.0);
            invert_color             = blendOverlay(invert_color, grey130); // compensate blue
        }
        
        //
        // write result
        //
        float4 awb = blendOverlay(inColor, invert_color);
        
        float4 result = float4(awb.rgb, adjustment.blending.opacity);
        
        return IMProcessing::blend(inColor, result, adjustment.blending);
    }
    
    kernel void kernel_adjustGray(
                                  texture2d<float, access::sample> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  constant float3&        dominantColor  [[buffer(0)]],
                                  constant IMPAdjustment& adjustment     [[buffer(1)]],
                                  constant bool&          compensateBlue [[buffer(2)]],
                                  uint2 gid [[thread_position_in_grid]]) {
        
        float4 inColor = sampledColor(inTexture, outTexture, gid);
        outTexture.write(adjustGray(inColor, dominantColor, adjustment, compensateBlue), gid);
    }
    }

#endif

#endif

#endif /* IMPAdjustmentWB_metal_h */
