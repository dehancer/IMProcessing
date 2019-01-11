//
//  IMPColorSpaces_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 19.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPColorSpaces_metal_h
#define IMPColorSpaces_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPOperations-Bridging-Metal.h"

using namespace metal;
#ifdef __cplusplus

namespace IMProcessing
{
   
//    inline float rgb_gamma_correct(float c, float gamma)
//    {
//        const float a = 0.055;
//        if(c < 0.0031308)
//            return 12.92*c;
//        else
//            return (1.0+a)*pow(c, 1.0/gamma) - a;
//    }
//    
//    inline float3 rgb_gamma_correct (float3 rgb, float gamma) {
//        return float3(
//                      rgb_gamma_correct(rgb.x,gamma),
//                      rgb_gamma_correct(rgb.y,gamma),
//                      rgb_gamma_correct(rgb.z,gamma)
//                      );
//    }
}
#endif

#endif
#endif /* IMPColorSpaces_metal_h */
