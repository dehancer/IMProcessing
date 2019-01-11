//
//  IMPGraphics_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 04.05.16.
//  Copyright © 2016 Dehancer.photo. All rights reserved.
//

#ifndef IMPGeometry_metal_h
#define IMPGeometry_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"

using namespace metal;

#ifdef __cplusplus

namespace IMProcessing
{
   
    vertex IMPVertexOut vertex_transformation(
                                              const device IMPVertex*      vertex_array [[ buffer(0) ]],
                                              const device float4x4&       matrix_model [[ buffer(1) ]],
                                              unsigned int vid [[ vertex_id ]]) {
        
        
        IMPVertex in = vertex_array[vid];
        float3 position = float3(in.position);
        
        IMPVertexOut out;
        out.position = matrix_model * float4(position,1);
        out.texcoord = float2(float3(in.texcoord).xy);
        
        return out;
    }
 
    vertex IMPVertexOut vertex_passthrough(
                                              const device IMPVertex*   vertex_array [[ buffer(0) ]],
                                              unsigned int vid [[ vertex_id ]]) {
        
        
        IMPVertex in = vertex_array[vid];
        float3 position = float3(in.position);
        
        IMPVertexOut out;
        out.position = float4(position,1);
        out.texcoord = float2(float3(in.texcoord).xy);
        
        return out;
    }
    

    vertex IMPVertexOut vertex_warpTransformation(
                                                  const device IMPVertex*   vertex_array     [[ buffer(0) ]],
                                                  const device float4x4    &homography_model [[ buffer(1) ]],
                                                  unsigned int vid [[ vertex_id ]]) {
        
        
        IMPVertex in = vertex_array[vid];
        float3 position = float3(in.position);
        
        IMPVertexOut out;
        out.position =    homography_model * float4(position,1);        
        out.texcoord = float2(float3(in.texcoord).xy);
        
        return out;
    }
    
    fragment float4 fragment_transformation(
                                            IMPVertexOut in [[stage_in]],
                                            const device float4  &flip [[ buffer(0) ]],
                                            texture2d<float, access::sample> texture [[ texture(0) ]]
                                            ) {
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        float2 flipHorizontal = flip.xy;
        float2 flipVertical   = flip.zw;
        float2 xy = float2(flipHorizontal.x+in.texcoord.x*flipHorizontal.y, flipVertical.x+in.texcoord.y*flipVertical.y);
        return texture.sample(baseSampler, xy);
    }
    
    fragment float4 fragment_passthrough(
                                         IMPVertexOut in [[stage_in]],
                                         texture2d<float, access::sample> texture [[ texture(0) ]]
                                         ) {
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        return  texture.sample(baseSampler, in.texcoord.xy);
    }
    
    fragment float4 fragment_gridGenerator(
                                           // поток вершин
                                           IMPVertexOut in [[stage_in]],
                                           // текстура фото-пластины
                                           texture2d<float, access::sample> texture [[ texture(0) ]],
                                           // шаг сетки в пиксела
                                           const device uint      &gridStep        [[ buffer(0) ]],
                                           // шаг дополнительной подсетки кратной основной
                                           const device uint      &gridSubDiv      [[ buffer(1) ]],
                                           // цвет сетки
                                           const device float4    &gridColor       [[ buffer(2) ]],
                                           // цвет подсетки
                                           const device float4    &gridSubDivColor [[ buffer(3) ]],
                                           // цвет области подсветки
                                           const device float4    &spotAreaColor   [[ buffer(4) ]],
                                           // область подсветки
                                           const device IMPRegion &spotArea        [[ buffer(5) ]],
                                           // типа заливки подсветки: 0 == .Grid, 1 == Solid
                                           const device uint      &spotAreaType    [[ buffer(6) ]]
                                           ) {
        
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        
        uint w = texture.get_width();
        uint h = texture.get_height();
        uint x = uint(in.texcoord.x*w);
        uint y = uint(in.texcoord.y*h);
        uint sd = gridStep*gridSubDiv;
        
        float4 inColor = texture.sample(baseSampler, in.texcoord.xy);
        float4 color = inColor;
        
        if (x == 0 ) return color;
        if (y == 0 ) return color;
        
        float2 coords  = float2(in.texcoord.x,in.texcoord.y);
        float  isBoxed = IMProcessing::coordsIsInsideBox(coords, float2(spotArea.left,spotArea.bottom), float2(1.0-spotArea.right,1.0-spotArea.top));
        
        if(x % sd == 0 || y % sd == 0 ) {
            color = IMProcessing::blendNormal(inColor, gridSubDivColor);
            
            if (x % 2 == 0 && y % 2 == 0) color = inColor;
            else if ((gridStep+1)%2 == 0) {
                if (x % 2 != 0 && y % 2 != 0) color = inColor;
            }
            
            if (spotAreaType == 0 && isBoxed) {
                color = IMProcessing::blendNormal(color, spotAreaColor);
            }
            
        }
        else if(x % gridStep==0 || y % gridStep==0) {
            
            color = IMProcessing::blendNormal(inColor, gridColor);
            
            if (x % 2 == 0 && y % 2 == 0) color = inColor;
            else if ((gridStep+1)%2 == 0) {
                if (x % 2 != 0 && y % 2 != 0) color = inColor;
            }
            
            if (spotAreaType == 0 && isBoxed) {
                color = IMProcessing::blendNormal(color, spotAreaColor);
            }
            
        }
        
        if (spotAreaType == 1 && isBoxed) {
            color = IMProcessing::blendNormal(color, spotAreaColor);
        }
        
        return color;
    }
    
    inline const float4x4 operator*(IMPFloat2x4x4 const tensor, float4 const vector) {
        float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
        for (int j=0; j<4; j++){
            for (int i=0; i<4; i++){
                v[j] += float4(tensor.vectors[i][j],0,0)*vector[i];
            }
        }
        return float4x4(v[0],v[1],v[2],v[3]);
    }
    
    inline const float4x4 operator*(float4 const vector, IMPFloat2x4x4 const tensor) {
        float4 v[4] = {float4(0),float4(0),float4(0),float4(0)};
        for (int j=0; j<4; j++){
            for (int i=0; i<4; i++){
                v[i] += float4(tensor.vectors[j][i],0,0)*vector[j];
            }
        }
        return float4x4(v[0],v[1],v[2],v[3]);
    }
    
    fragment float4 fragment_bezierWarpTransformation(
                                                      IMPVertexOut in [[stage_in]],
                                                      // исходная текстура
                                                      texture2d<float, access::sample>  inTexture [[texture(0)]],
                                                      // контрольные точки
                                                      const device IMPFloat2x4x4        &surface  [[ buffer(0) ]],
                                                      // цвет фона
                                                      const device float4               &color    [[ buffer(1) ]]
                                                      ){
        
        //constexpr sampler s(address::clamp_to_zero, filter::linear, coord::normalized);
        float3 p = float3(in.texcoord.xy,0);
        
        //
        // Q(u,v) = (u^3,u^2,u,1)B[P]B(v^3,v^2,v,1)
        // где [P] - тензор контрольных точек
        // https://en.wikipedia.org/wiki/Non-uniform_rational_B-spline
        // http://sernam.ru/book_mm3d.php?id=109
        // https://youtu.be/4sKocFWugiM
        //
        float4x4 B = {
            {-1,  3, -3, 1},
            { 3, -6,  3, 0},
            {-3,  3,  0, 0},
            { 1,  0,  0, 0}
        };
        
        float4 BU = float4(pow(p.x,3), pow(p.x,2), p.x, 1) * B;
        float4 BV = B * float4(pow(p.y,3), pow(p.y,2), p.y, 1);
        
        float4 position = surface*BV*BU;
        
        float4 inColor = inTexture.sample(baseSampler,position.xy);
        
        if (inColor.a==0) {
            inColor = color;
        }
        
        return inColor;
        
    }
}

typedef struct {
    packed_float2 position;
    packed_float2 texcoord;
} VertexIn;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} VertexOut;


#endif

#endif

#endif /* IMPGeometry_metal_h */
