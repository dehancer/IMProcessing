//
//  IMPCubeLut_metal.h
//  Pods
//
//  Created by denis svinarchuk on 26.08.17.
//
//

#ifndef IMPCubeLut_metal_h
#define IMPCubeLut_metal_h

#ifdef __METAL_VERSION__

#ifdef __cplusplus

#include <metal_stdlib>
#include <simd/simd.h>
#include "IMPSwift-Bridging-Metal.h"
#include "IMPConstants_metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

namespace IMProcessing
{
        
    constexpr sampler lutSampler(address::clamp_to_edge, filter::linear, coord::normalized);
    
    kernel void kernel_clutColorMapper(
                                       texture3d<float, access::sample> clut      [[texture(0)]],
                                       device float3                   *reference [[buffer(0)]],
                                       device float3                   *target    [[buffer(1)]],
                                       uint gid [[thread_position_in_grid]]
                                       )
    {
        float3 rgb = reference[gid];
        target[gid] =  clut.sample(lutSampler, rgb).rgb;     
    }
    
    
    inline float3 compress(float3 rgb, float2 compression) {
        //return  pow(compression.x*rgb + compression.y, 1/1.8);
        return  compression.x*rgb + compression.y;
    }
    
    
    ///
    /// @brief Kernel optimized 3D LUT identity
    ///
    kernel void kernel_make3DLut(
                                 texture3d<float, access::write>         d3DLut     [[texture(0)]],
                                 constant float2  &compression [[buffer(0)]],
                                 uint3 gid [[thread_position_in_grid]]){
                
        float3 denom = float3(d3DLut.get_width()-1,d3DLut.get_height()-1,d3DLut.get_depth()-1);
        float4 input_color  = float4(compress(float3(gid)/denom, compression),1);
        d3DLut.write(input_color, gid);
    }
    
    
    ///
    /// @brief Kernel optimized 2D LUT identity
    ///
    kernel void kernel_make2DLut(
                                 texture2d<float, access::write>         d2DLut     [[texture(0)]],
                                 constant float2  &compression [[buffer(0)]],
                                 constant uint    &clevel      [[buffer(1)]],
                                 uint2 gid [[thread_position_in_grid]]){
        
        float qsize = float(clevel*clevel);
        float denom = qsize-1;
        
        uint  bindex = (floor(float(gid.x) / denom) + float(clevel) * floor( float(gid.y)/qsize));
        float b = bindex/denom;
        
        float xindex = floor(float(gid.x) / qsize);
        float yindex = floor(float(gid.y) / qsize);
        float r = (float(gid.x)-xindex*(qsize))/(qsize-1);
        float g = (float(gid.y)-yindex*(qsize))/(qsize-1);
        
        float3 rgb = compress(float3(r,g,b),compression);
        
        d2DLut.write(float4(rgb,1),gid.xy);
    }
    
    ///
    /// @brief Kernel optimized 1D LUT identity
    ///
    kernel void kernel_make1DLut(
                                 texture1d<float, access::write>   d1DLut     [[texture(0)]],
                                 constant float2  &compression                [[buffer(0)]],
                                 uint gid [[thread_position_in_grid]]){
        
        float3 denom = float3(d1DLut.get_width()-1);
        float4 input_color  = float4(compress(float3(gid)/denom, compression),1);
        d1DLut.write(input_color, gid);
    }
    
    ///
    /// @brief Kernel optimized convertion from 3D LUT to new 2D Lut
    ///
    kernel void kernel_convert3DLut_to_2DLut(
                                             texture3d<float, access::sample>    d3DLut       [[texture(0)]],
                                             texture2d<float, access::read>      d2DLutSource [[texture(1)]],
                                             texture2d<float, access::write>     d2DLut       [[texture(2)]],
                                             uint2 gid [[thread_position_in_grid]]){
        
        
        float3 rgb    = d2DLutSource.read(gid).rgb;
        float4 result = d3DLut.sample(lutSampler, rgb);
        
        d2DLut.write(float4(result.rgb,1),gid);
    }
    
    kernel void kernel_resample3DLut_to_3DLut(
                                              texture3d<float, access::sample>    d3DLut       [[texture(0)]],
                                              texture3d<float, access::read>      d3DLutSource [[texture(1)]],
                                              texture3d<float, access::write>     d3DLutOut    [[texture(2)]],
                                              uint3 gid [[thread_position_in_grid]]){
        
        float3 rgb    = d3DLutSource.read(gid).rgb;
        float3 result = d3DLut.sample(lutSampler, rgb).rgb;
        
        d3DLutOut.write(float4(result,1),gid);
    }
    
    /**
     Look up color in Hald-like 2D representaion of 3D LUT
     
     @param rgb input color
     @param d2DLut d2DLut Hald-like texture: cube-size*cube-size * level = r-g * b boxed regiones
     @param inClevel level
     @return maped color
     */
    static inline float3 sample2DLut(float3 rgb,  texture2d<float, access::sample> d2DLut, uint inClevel){
        float  size    = float(d2DLut.get_width());
        float  clevel  = float(inClevel);
        
        float cube_size = clevel*clevel;
        
        float blueColor = rgb.b * (cube_size-1);
        
        float2 quad1;
        quad1.y = floor(floor(blueColor) / clevel);
        quad1.x = floor(blueColor) - (quad1.y * clevel);
        
        float2 quad2;
        quad2.y = floor(ceil(blueColor) / clevel);
        quad2.x = ceil(blueColor) - (quad2.y * clevel);
        
        float2 texPos1;
        
        float denom = 1/clevel;
        
        texPos1.x = (quad1.x * denom) + 0.5/size + ((denom - 1.0/size) * rgb.r);
        texPos1.y = (quad1.y * denom) + 0.5/size + ((denom - 1.0/size) * rgb.g);
        
        float2 texPos2;
        texPos2.x = (quad2.x * denom) + 0.5/size + ((denom - 1.0/size) * rgb.r);
        texPos2.y = (quad2.y * denom) + 0.5/size + ((denom - 1.0/size) * rgb.g);
        
        float4 newColor1 = d2DLut.sample(lutSampler, texPos1);
        float4 newColor2 = d2DLut.sample(lutSampler, texPos2);
        
        return mix(newColor1, newColor2, fract(blueColor)).rgb;
    }
    
    ///
    /// @brief Kernel optimized convertion from 2D LUT to new 3D Lut
    ///
    kernel void kernel_convert2DLut_to_3DLut(
                                             texture2d<float, access::sample>    d2DLut       [[texture(0)]],
                                             texture3d<float, access::read>      d3DLutSource [[texture(1)]],
                                             texture3d<float, access::write>     d3DLut       [[texture(2)]],
                                             constant uint  &inClevel [[buffer(0)]],
                                             uint3 gid [[thread_position_in_grid]]){
        
        float3 color = sample2DLut(d3DLutSource.read(gid).rgb, d2DLut, inClevel);
        d3DLut.write(float4(color.r,color.g,color.b,1),gid);
    }
    
    ///
    /// @brief Kernel optimized convertion from 1D LUT to new 3D Lut
    ///
    kernel void kernel_convert1DLut_to_3DLut(
                                             texture1d<float, access::sample>    d1DLut       [[texture(0)]],
                                             texture3d<float, access::read>      d3DLutSource [[texture(1)]],
                                             texture3d<float, access::write>     d3DLut       [[texture(2)]],
                                             uint3 gid [[thread_position_in_grid]]){
        
        float3 rgb     = d3DLutSource.read(gid).rgb;
        
        float x = d1DLut.sample(lutSampler, rgb.x).x;
        float y = d1DLut.sample(lutSampler, rgb.y).y;
        float z = d1DLut.sample(lutSampler, rgb.z).z;
        
        d3DLut.write(float4(x,y,z, 1),gid);
        
    }
    
    ///
    /// @brief Kernel optimized convertion from 1D LUT to new 2D Lut
    ///
    kernel void kernel_convert1DLut_to_2DLut(
                                             texture1d<float, access::sample>    d1DLut       [[texture(0)]],
                                             texture2d<float, access::read>      d2DLutSource [[texture(1)]],
                                             texture2d<float, access::write>     d2DLut       [[texture(2)]],
                                             uint2 gid [[thread_position_in_grid]]){
        
        float3 rgb     = d2DLutSource.read(gid).rgb;
        
        float x = d1DLut.sample(lutSampler, rgb.x).x;
        float y = d1DLut.sample(lutSampler, rgb.y).y;
        float z = d1DLut.sample(lutSampler, rgb.z).z;
        
        d2DLut.write(float4(x,y,z, 1),gid);
        
    }
    
    ///
    /// @brief Kernel optimized convertion from 1D Array LUT to new 2D Lut
    ///
    kernel void kernel_convert1DArrayLut_to_2DLut(
                                                  texture1d_array<float, access::sample> d1DLut       [[texture(0)]],
                                                  texture2d<float, access::read>         d2DLutSource [[texture(1)]],
                                                  texture2d<float, access::write>        d2DLut       [[texture(2)]],
                                                  uint2 gid [[thread_position_in_grid]]){
        
        float3 rgb     = d2DLutSource.read(gid).rgb;
                
        float x = d1DLut.sample(lutSampler, rgb.x, 0).x;
        float y = d1DLut.sample(lutSampler, rgb.y, 1).x;
        float z = d1DLut.sample(lutSampler, rgb.z, 2).x;

        d2DLut.write(float4(x,y,z, 1),gid);
        
    }
    
    ///
    /// @brief Kernel optimized convertion from 1D Array LUT to new 3D Lut
    ///
    kernel void kernel_convert1DArrayLut_to_3DLut(
                                                  texture1d_array<float, access::sample> d1DLut       [[texture(0)]],
                                                  texture3d<float, access::read>         d3DLutSource [[texture(1)]],
                                                  texture3d<float, access::write>        d3DLut       [[texture(2)]],
                                                  uint3 gid [[thread_position_in_grid]]){
        
        float3 rgb     = d3DLutSource.read(gid).rgb;
        
        float x = d1DLut.sample(lutSampler, rgb.x, 0).x;
        float y = d1DLut.sample(lutSampler, rgb.y, 1).x;
        float z = d1DLut.sample(lutSampler, rgb.z, 2).x;
        
        d3DLut.write(float4(x,y,z, 1),gid);        
    }
    
    ///
    /// @brief Kernel optimized convertion from 2D LUT to new 1D Lut
    ///
    kernel void kernel_convert1DArrayLut_to_1DLut(
                                                  texture1d_array<float, access::sample> d1DLut       [[texture(0)]],
                                                  texture1d<float, access::read>         d1DLutSource [[texture(1)]],
                                                  texture1d<float, access::write>        d1DLutDest   [[texture(2)]],
                                                  uint gid [[thread_position_in_grid]]){
        
        float3 rgb     = d1DLutSource.read(gid).rgb;

        float x = d1DLut.sample(lutSampler, rgb.x, 0).x;
        float y = d1DLut.sample(lutSampler, rgb.y, 1).x;
        float z = d1DLut.sample(lutSampler, rgb.z, 2).x;
        
        d1DLutDest.write(float4(x,y,z,1),gid);
    }
    
    
    ///
    /// @brief Kernel optimized convertion from 2D LUT to new 1D Lut
    ///
    kernel void kernel_convert2DLut_to_1DLut(
                                             texture2d<float, access::sample>    d2DLut       [[texture(0)]],
                                             texture1d<float, access::read>      d1DLutSource [[texture(1)]],
                                             texture1d<float, access::write>     d1DLut       [[texture(2)]],
                                             constant uint  &inClevel [[buffer(0)]],
                                             uint gid [[thread_position_in_grid]]){
        
        float3 color = sample2DLut(d1DLutSource.read(gid).rgb, d2DLut, inClevel);
        d1DLut.write(float4(color.r,color.g,color.b,1),gid);
    }
    
    ///
    /// @brief Kernel optimized convertion from 3D LUT to new 1D Lut
    ///
    kernel void kernel_convert3DLut_to_1DLut(
                                             texture3d<float, access::sample>    d3DLut       [[texture(0)]],
                                             texture1d<float, access::read>      d1DLutSource [[texture(1)]],
                                             texture1d<float, access::write>     d1DLut       [[texture(2)]],
                                             uint gid [[thread_position_in_grid]]){
        
        float3 rgb    = d1DLutSource.read(gid).rgb;
        float4 result = d3DLut.sample(lutSampler, rgb);
        
        d1DLut.write(float4(result.rgb,1),gid);
    }
    
    
    inline  float4 adjustLutD3D(
                                float4 inColor,
                                texture3d<float, access::sample>  lut,
                                constant IMPAdjustment            &adjustment
                                ){
        
        float4 result = lut.sample(lutSampler, inColor.rgb);

        result = IMProcessing::blend(inColor, result, adjustment.blending); 
        
        return result;
    }
    
    inline float4 adjustLutD1D(
                               float4 inColor,
                               texture1d<float, access::sample>  lut,
                               constant IMPAdjustment            &adjustment
                               ){
        
        half red   = lut.sample(lutSampler, inColor.r).r;
        half green = lut.sample(lutSampler, inColor.g).g;
        half blue  = lut.sample(lutSampler, inColor.b).b;

        float4 result = IMProcessing::blend(inColor, float4(red, green, blue,1), adjustment.blending); 
        
        return result;
    }
    
    kernel void kernel_adjustLutD1D(texture2d<float, access::sample>  inTexture       [[texture(0)]],
                                    texture2d<float, access::write>   outTexture      [[texture(1)]],
                                    texture1d<float, access::sample>  lut             [[texture(2)]],
                                    constant IMPAdjustment           &adjustment      [[buffer(0)]],
                                    uint2 gid [[thread_position_in_grid]]){
        
        float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
        float4 result  = adjustLutD1D(inColor,lut,adjustment);
        outTexture.write(result, gid);
    }
    
    kernel void kernel_adjustLutD3D(
                                    texture2d<float, access::sample>  inTexture       [[texture(0)]],
                                    texture2d<float, access::write>   outTexture      [[texture(1)]],
                                    texture3d<float, access::sample>  lut             [[texture(2)]],
                                    constant IMPAdjustment           &adjustment      [[buffer(0)]],
                                    uint2 gid [[thread_position_in_grid]]){
        
        float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);
        float4 result  = adjustLutD3D(inColor,lut,adjustment);
        outTexture.write(result, gid);
    }
    
    kernel void kernel_adjustLutD2D(
                                    texture2d<float, access::sample>  inTexture       [[texture(0)]],
                                    texture2d<float, access::write>   outTexture      [[texture(1)]],
                                    texture2d<float, access::sample>  lut             [[texture(2)]],
                                    constant IMPAdjustment           &adjustment      [[buffer(0)]],
                                    constant uint  &inClevel [[buffer(1)]],
                                    uint2 gid [[thread_position_in_grid]]){
        
        float4 inColor = IMProcessing::sampledColor(inTexture,outTexture,gid);

        float4 result = IMProcessing::blend(inColor, float4(sample2DLut(inColor.rgb, lut, inClevel),1), adjustment.blending); 
        
        outTexture.write(result, gid);
    }
    
}

#endif
#endif
#endif /* IMPCubeLut_metal_h */
