//
//  IMPStdlib_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPStdlib_metal_h
#define IMPStdlib_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
#include <simd/simd.h>

#include "IMPSwift-Bridging-Metal.h"
#include "IMPConstants_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"
#include "IMPGeometry_metal.h"
#include "IMPTpsSolverCommon.h"

#include "IMPDerivatives_metal.h"

#include "IMPGaussianBlur_metal.h"
#include "IMPCrosshair_metal.h"

#include "IMPColorProcessing_metal.h"
#include "IMPHoughTransform_metal.h"
#include "IMPMorphology_metal.h"

#include "IMPPosterize_metal.h"
#include "IMPMedian_metal.h"
#include "IMPSobelEdges_metal.h"
#include "IMPHarrisCornersDetector_metal.h"
#include "IMPHarrisCorners_metal.h"
#include "IMPConvolution_metal.h"
#include "IMPAdaptiveThreshold_metal.h"
#include "IMPCChekerDetector_metal.h"

#include "IMPCurves_metal.h"
#include "IMPHistogram_metal.h"
#include "IMPCLut_metal.h"
#include "IMPWhiteBalance_metal.h"
#include "IMPContrastScretching_metal.h"

#include "IMPTpsTransform_metal.h"

//#include "IMPHistogramLayer_metal.h"
//#include "IMPAdjustment_metal.h"
//#include "IMPRandomNoise_metal.h"
//#include "IMPFilmGrain_metal.h"
//#include "IMPDithering_metal.h"
#include "IMPVignette_metal.h"
#include "IMPSaturation_metal.h"
#include "IMPAdjustGray_metal.h"

#ifdef __cplusplus

namespace IMProcessing
{
    kernel void kernel_passthrough(texture2d<float, access::sample> inTexture [[texture(0)]],
                                   texture2d<float, access::write> outTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = sampledColor(inTexture,outTexture,gid);
        outTexture.write(inColor, gid);
    }
    
    kernel void kernel_desaturate(texture2d<float, access::sample> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = sampledColor(inTexture,outTexture,gid);
        inColor.rgb = float3(dot(inColor.rgb,kIMP_Y_mean_factor));
        outTexture.write(inColor, gid);
    }
}

#endif

#endif

#endif /*IMPStdlib_metal_h*/
