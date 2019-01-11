//
//  IMProcessing-Bridg-Lib.h
//  Pods
//
//  Created by denis svinarchuk on 03.05.17.
//
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#include "IMPConstants-Bridging-Metal.h"
#include "IMPTypes-Bridging-Metal.h"
#include "IMPTpsSolverCommon.h"
#include "IMPTpsSolver.h"

@interface IMPBridge : NSObject

+ (float3) rgb2xyz:(float3)color;     // 0
+ (float3) rgb2srgb:(float3)color;    // 1
+ (float3) rgb2lab:(float3)color;     // 2
+ (float3) rgb2lch:(float3)color;     // 3
+ (float3) rgb2dcproflut:(float3)color;     // 4
+ (float3) rgb2hsv:(float3)color;     // 5
+ (float3) rgb2hsl:(float3)color;     // 6
+ (float3) rgb2hsp:(float3)color;     // 6
+ (float3) rgb2ycbcrHD:(float3)color; // 7

+ (float3) srgb2xyz:(float3)color;     // 0
+ (float3) srgb2rgb:(float3)color;     // 1
+ (float3) srgb2lab:(float3)color;     // 2
+ (float3) srgb2lch:(float3)color;     // 3
+ (float3) srgb2dcproflut:(float3)color;     // 4
+ (float3) srgb2hsv:(float3)color;     // 5
+ (float3) srgb2hsl:(float3)color;     // 6
+ (float3) srgb2hsp:(float3)color;     // 6
+ (float3) srgb2ycbcrHD:(float3)color; // 7

+ (float3) hsv2rgb:(float3)color;     // 1
+ (float3) hsv2srgb:(float3)color;     // 1
+ (float3) hsv2xyz:(float3)color;     // 2
+ (float3) hsv2lab:(float3)color;     // 3
+ (float3) hsv2lch:(float3)color;     // 4
+ (float3) hsv2dcproflut:(float3)color;     // 5
+ (float3) hsv2ycbcrHD:(float3)color; // 6
+ (float3) hsv2hsl:(float3)color;     // 7
+ (float3) hsv2hsp:(float3)color;     // 7

+ (float3) hsl2rgb:(float3)color;
+ (float3) hsl2srgb:(float3)color;
+ (float3) hsl2hsv:(float3)color;
+ (float3) hsl2lab:(float3)color;
+ (float3) hsl2lch:(float3)color;
+ (float3) hsl2dcproflut:(float3)color;
+ (float3) hsl2xyz:(float3)color;
+ (float3) hsl2ycbcrHD:(float3)color;  // 7
+ (float3) hsl2hsp:(float3)color;

+ (float3) xyz2rgb:(float3)color;
+ (float3) xyz2srgb:(float3)color;
+ (float3) xyz2lab:(float3)color;
+ (float3) xyz2lch:(float3)color;
+ (float3) xyz2dcproflut:(float3)color;
+ (float3) xyz2hsv:(float3)color;
+ (float3) xyz2hsl:(float3)color;
+ (float3) xyz2hsp:(float3)color;
+ (float3) xyz2ycbcrHD:(float3)color;  // 7

+ (float3) lab2rgb:(float3)color;
+ (float3) lab2srgb:(float3)color;
+ (float3) lab2lch:(float3)color;
+ (float3) lab2dcproflut:(float3)color;
+ (float3) lab2hsv:(float3)color;
+ (float3) lab2hsl:(float3)color;
+ (float3) lab2hsp:(float3)color;
+ (float3) lab2xyz:(float3)color;
+ (float3) lab2ycbcrHD:(float3)color; // 7

+ (float3) dcproflut2rgb:(float3)color;
+ (float3) dcproflut2srgb:(float3)color;
+ (float3) dcproflut2lab:(float3)color;
+ (float3) dcproflut2lch:(float3)color;
+ (float3) dcproflut2hsv:(float3)color;
+ (float3) dcproflut2hsl:(float3)color;
+ (float3) dcproflut2hsp:(float3)color;
+ (float3) dcproflut2xyz:(float3)color;
+ (float3) dcproflut2ycbcrHD:(float3)color; // 7

+ (float3) lch2rgb:(float3)color;
+ (float3) lch2srgb:(float3)color;
+ (float3) lch2lab:(float3)color;
+ (float3) lch2dcproflut:(float3)color;
+ (float3) lch2hsv:(float3)color;
+ (float3) lch2hsl:(float3)color;
+ (float3) lch2hsp:(float3)color;
+ (float3) lch2xyz:(float3)color;
+ (float3) lch2ycbcrHD:(float3)color;

+ (float3) ycbcrHD2rgb:(float3)color;
+ (float3) ycbcrHD2srgb:(float3)color;
+ (float3) ycbcrHD2lab:(float3)color;
+ (float3) ycbcrHD2lch:(float3)color;
+ (float3) ycbcrHD2dcproflut:(float3)color;
+ (float3) ycbcrHD2hsv:(float3)color;
+ (float3) ycbcrHD2hsl:(float3)color;
+ (float3) ycbcrHD2hsp:(float3)color;
+ (float3) ycbcrHD2xyz:(float3)color;

+ (float3) hsp2rgb:(float3)color;
+ (float3) hsp2srgb:(float3)color;
+ (float3) hsp2hsv:(float3)color;
+ (float3) hsp2hsl:(float3)color;
+ (float3) hsp2lab:(float3)color;
+ (float3) hsp2lch:(float3)color;
+ (float3) hsp2dcproflut:(float3)color;
+ (float3) hsp2xyz:(float3)color;
+ (float3) hsp2ycbcrHD:(float3)color;  // 7


+ (float3) convert:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(float3)value;
+ (float3) toNormalized:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(float3)value;
+ (float3) fromNormalized:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(float3)value;

+ (float2) xyz2xy:(float3)color;
+ (float3) xy2xyz:(float2)coord;

+ (float2) xy2TempTint:(float2)coord;
+ (float2) tempTint2xy:(float2)tempTint;
+ (float)  xyz2CorColorTemp:(float3)color;

+ (float2) tempTintFor:(float3)color from:(float3)gray;
+ (float3) adjustTempTint:(float2)tempTint for:(float3)color;

@end
