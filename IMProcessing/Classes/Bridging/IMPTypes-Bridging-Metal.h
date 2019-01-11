//
//  IMPTypes.h
//  IMProcessing
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPTypes_h
#define IMPTypes_h

#include "IMPConstants-Bridging-Metal.h"

#ifndef __METAL_VERSION__
#import <Foundation/Foundation.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
    
    typedef struct {
        float2 vectors[4][4];
    } IMPFloat2x4x4;
    

#ifndef __METAL_VERSION__
    
     typedef struct {
        float3 position;
        float3 texcoord;
    } IMPVertex;

#else
    
    typedef struct {
        packed_float3 position;
        packed_float3 texcoord;
    } IMPVertex;

    typedef struct {
        float4 position [[position]];
        float2 texcoord;
    } IMPVertexOut;

#endif
    
    typedef enum:int {
        IMPRgbSpace     = 0,
        IMPsRgbSpace    = 1,
        IMPLabSpace     = 2,
        IMPLchSpace     = 3,
        IMPXyzSpace     = 4,
        IMPDCProfLutSpace     = 5,
        IMPHsvSpace     = 6,
        IMPHslSpace     = 7,
        IMPYcbcrHDSpace = 8, // Full-range type
        IMPHspSpace     = 9  // http://alienryderflex.com/hsp.html
    } IMPColorSpaceIndex;

#ifndef __METAL_VERSION__
    
    typedef NS_ENUM(uint, IMPBlendingMode) {
        IMPNormal     = 0,
        IMPLuminosity = 1,
        IMPColor      = 2,
        IMPMix        = 3
    };
    
#else
    
    typedef enum : uint {
        IMPNormal     = 0,
        IMPLuminosity = 1,
        IMPColor      = 2,
        IMPMix        = 3
    }IMPBlendingMode;
    
#endif
  
    typedef struct {
        float2 position;
        float2 slope;
    } IMPEdgel;
    
    typedef struct{
        IMPEdgel array[1024];
    }IMPEdgelList;

    typedef struct {
        float2 point;
        float4 slope; // x - left, y - top, z - bottom, w - right
        float4 color;
    } IMPCorner;

    
    typedef struct {
        float left;
        float right;
        float top;
        float bottom;
    } IMPRegion;
    
    typedef struct {
        float2 point[3][3];
    } IMPGradientCoords;
    
    typedef struct {
        IMPBlendingMode    mode;
        float              opacity;
    } IMPBlending;
    
    typedef struct{
        IMPBlending    blending;
    } IMPAdjustment;
    
    typedef struct{
        float4   dominantColor;
        IMPBlending    blending;
    } IMPWBAdjustment;
    
    typedef struct{
        float        value;
        IMPBlending  blending;
    } IMPValueAdjustment;
    
    typedef struct{
        float        level;
        IMPBlending  blending;
    } IMPLevelAdjustment;
    
    
    typedef struct{
        float4   minimum;
        float4   maximum;
        IMPBlending    blending;
    } IMPContrastAdjustment;
    
    typedef struct{
        float hue;
        float saturation;
        float value;
    }IMPHSVLevel;
    
    typedef struct {
        IMPHSVLevel   master;
        IMPHSVLevel   levels[kIMP_Color_Ramps];
        IMPBlending   blending;
    } IMPHSVAdjustment;
    
    typedef struct {
        float total;
        float color;
        float luma;
    }IMPFilmGrainColor;
    
    typedef struct {
        bool                isColored;
        float               size;
        IMPFilmGrainColor   amount;
        IMPBlending         blending;
    } IMPFilmGrainAdjustment;
    
    
#ifdef __cplusplus
}
#endif

#endif /* IMPTypes_h */
