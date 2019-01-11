//
//  IMPConstants-Bridging-Metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 22.12.15.
//  Copyright © 2015 Dehancer.photo. All rights reserved.
//

#ifndef IMPConstants_Bridging_Metal_h
#define IMPConstants_Bridging_Metal_h

#ifdef __METAL_VERSION__

# include <metal_stdlib>
using namespace metal;

#define vector_step metal::step
#define vector_mix  metal::mix
#define vector_fract metal::fract
#define vector_clamp metal::clamp

#else

# include <stdlib.h>
# include <simd/simd.h>

# define M_PI_F M_PI

# define constant const
# define float4 vector_float4
# define float3 vector_float3
# define float2 vector_float2
# define uint4  vector_uint4
# define uint3  vector_uint3
# define uint2  vector_uint2

# define float2x2 matrix_float2x2
# define float3x3 matrix_float3x3
# define float4x4 matrix_float4x4

# define float2x3 matrix_float2x3
# define float3x2 matrix_float3x2

# define float3x4 matrix_float3x4
# define float4x3 matrix_float4x3

# define float2x4 matrix_float2x4
# define float4x2 matrix_float4x2

# define constexpr

#endif

# include <simd/simd.h>

static constant float kIMP_Std_Gamma      = 2.2;
static constant float kIMP_RGB2SRGB_Gamma = 2.4;

static constant float kIMP_Cielab_X = 95.047;
static constant float kIMP_Cielab_Y = 100.000;
static constant float kIMP_Cielab_Z = 108.883;

// YCbCr luminance(Y) values
static constant float3 kIMP_Y_YCbCr_factor = {0.299, 0.587, 0.114};

// average
static constant float3 kIMP_Y_mean_factor = {0.3333, 0.3333, 0.3333};

// sRGB luminance(Y) values
static constant float3 kIMP_Y_YUV_factor = {0.2125, 0.7154, 0.0721};


#define  kIMP_Color_Ramps  6

static constant float4 kIMP_HSV_K0      = {0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0};
static constant float4 kIMP_HSV_K1      = {0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0};
static constant float4 kIMP_Reds        = {315.0, 345.0, 15.0,   45.0};
static constant float4 kIMP_Yellows     = { 15.0,  45.0, 75.0,  105.0};
static constant float4 kIMP_Greens      = { 75.0, 105.0, 135.0, 165.0};
static constant float4 kIMP_Cyans       = {135.0, 165.0, 195.0, 225.0};
static constant float4 kIMP_Blues       = {195.0, 225.0, 255.0, 285.0};
static constant float4 kIMP_Magentas    = {255.0, 285.0, 315.0, 345.0};

static constant float kIMP_COLOR_TEMP = 5000.0;
static constant float kIMP_COLOR_TINT = 0.0;

#endif /* IMPConstants_Bridging_Metal_h */
