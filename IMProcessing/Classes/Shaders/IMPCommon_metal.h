//
//  IMPCommon_metal.h
//  IMProcessing
//
//  Created by denis svinarchuk on 17.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPCommon_metal_h
#define IMPCommon_metal_h

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
    
    // maxComponent
    
    inline float sinc(float x){
        return sin(x*M_PI_H)/(x*M_PI_H);
    }
    
    inline float lanczos(float x, float a){
        if (x == 0.0) { return 1.0;}
        if (abs(x)<a) {return sinc(x) * sinc(x/a); }
        return 0.0;
    }
    
    inline float gaus_distribution(float x, float fi, float mu, float sigma){
        return fi * exp(- pow( (x-mu),2.0) / (2* pow(sigma,2.0)));
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 2> v) {
        return max(v[0], v[1]);
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 3> v) {
        return max(v[0], max(v[1], v[2]));
    }
    
    template<typename T> METAL_FUNC T max_component(vec<T, 4> v) {
        vec<T, 2> v2 = max(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
        return max(v2[0], v2[1]);
    }
    
    // minComponent
    
    template<typename T> METAL_FUNC T min_component(vec<T, 2> v) {
        return min(v[0], v[1]);
    }
    
    template<typename T> METAL_FUNC T min_component(vec<T, 3> v) {
        return min(v[0], min(v[1], v[2]));
    }
    
    template<typename T> METAL_FUNC T min_component(vec<T, 4> v) {
        vec<T, 2> v2 = min(vec<T, 2>(v[0], v[1]), vec<T, 2>(v[2], v[3]));
        return min(v2[0], v2[1]);
    }
    
    
    template<typename T> METAL_FUNC T lum(vec<T, 3> c) {
        return dot(c, kIMP_Y_YCbCr_factor);
    }
    
    
    inline float3 clipcolor_wlum(float3 c, float wlum) {
        
        float l = wlum;
        float n = min_component(c);
        float x = max_component(c);
        
        if (n < 0.0) {
            float v = 1.0/(l - n);
            c.r = l + ((c.r - l) * l) * v;
            c.g = l + ((c.g - l) * l) * v;
            c.b = l + ((c.b - l) * l) * v;
        }
        if (x > 1.0) {
            float v = 1.0/(x - l);
            c.r = l + ((c.r - l) * (1.0 - l)) * v;
            c.g = l + ((c.g - l) * (1.0 - l)) * v;
            c.b = l + ((c.b - l) * (1.0 - l)) * v;
        }
        
        return c;
    }
    
    inline float3 clipcolor(float3 c) {
        float l = lum(c);
        float n = min(min(c.r, c.g), c.b);
        float x = max(max(c.r, c.g), c.b);
        
        if (n < 0.0) {
            c.r = l + ((c.r - l) * l) / (l - n);
            c.g = l + ((c.g - l) * l) / (l - n);
            c.b = l + ((c.b - l) * l) / (l - n);
        }
        if (x > 1.0) {
            c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
            c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
            c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
        }
        
        return c;
    }
    
    inline float3 setlum(float3 c, float l) {
        float d = l - lum(c);
        c = c + float3(d);
        return clipcolor(c);
    }
    
    inline  float sat(float3 c) {
        float n = min_component(c);
        float x = max_component(c);
        return x - n;
    }
    
    inline  float mid(float cmin, float cmid, float cmax, float s) {
        return ((cmid - cmin) * s) / (cmax - cmin);
    }
    
    inline  float3 setsat(float3 c, float s) {
        if (c.r > c.g) {
            if (c.r > c.b) {
                if (c.g > c.b) {
                    /* g is mid, b is min */
                    c.g = mid(c.b, c.g, c.r, s);
                    c.b = 0.0;
                } else {
                    /* b is mid, g is min */
                    c.b = mid(c.g, c.b, c.r, s);
                    c.g = 0.0;
                }
                c.r = s;
            } else {
                /* b is max, r is mid, g is min */
                c.r = mid(c.g, c.r, c.b, s);
                c.b = s;
                c.r = 0.0;
            }
        } else if (c.r > c.b) {
            /* g is max, r is mid, b is min */
            c.r = mid(c.b, c.r, c.g, s);
            c.g = s;
            c.b = 0.0;
        } else if (c.g > c.b) {
            /* g is max, b is mid, r is min */
            c.b = mid(c.r, c.b, c.g, s);
            c.g = s;
            c.r = 0.0;
        } else if (c.b > c.g) {
            /* b is max, g is mid, r is min */
            c.g = mid(c.r, c.g, c.b, s);
            c.b = s;
            c.r = 0.0;
        } else {
            c = float3(0.0);
        }
        return c;
    }

    constexpr sampler baseSampler(address::clamp_to_edge, filter::linear, coord::normalized);

    inline float4 sampledColor(
                               texture2d<float, access::sample> inTexture,
                               texture2d<float, access::write> outTexture,
                               uint2 gid
                               ){
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        float w = outTexture.get_width();
        return mix(inTexture.sample(baseSampler, float2(gid) * float2(1.0/w, 1.0/outTexture.get_height())),
                   inTexture.read(gid),
                   IMProcessing::when_eq(inTexture.get_width(), w) // whe equal read exact texture color
                   );
    }
    
    
    ///  @brief Get a sample acording texture scale factor value.
    ///
    ///  @param inTexture       input texture
    ///  @param scale           scale factor
    ///  @param gid             position thread in grrid, equal x,y coordiant position of pixel in texure
    ///
    ///  @return sampled color value
    ///
    inline float4 sampledColor(
                               texture2d<float, access::sample> inTexture,
                               float                   scale,
                               uint2 gid
                               ){
        //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
        
        float w = float(inTexture.get_width())  * scale;
        float h = float(inTexture.get_height()) * scale;
        
        return mix(inTexture.sample(baseSampler, float2(gid) * float2(1.0/w, 1.0/h)),
                   inTexture.read(gid),
                   IMProcessing::when_eq(inTexture.get_width(), w) // whe equal read exact texture color
                   );
    }
    
    
    ///  @brief Test is there pixel inside in a box or not
    ///
    ///  @param v          pixel coordinate
    ///  @param bottomLeft offset from bottom-left conner
    ///  @param topRight   offset from top-right conner
    ///
    ///  @return 0 or 1
    ///
    inline  float coordsIsInsideBox(float2 v, float2 bottomLeft, float2 topRight) {
        float2 s =  step(bottomLeft, v) - step(topRight, v);
        return s.x * s.y;
    }
    
    inline float4 sampledColor(
                                        texture2d<float, access::sample>  inTexture,
                                        constant IMPRegion               &regionIn,
                                        float                             scale,
                                        uint2 gid){
        
        float w = float(inTexture.get_width())  * scale;
        float h = float(inTexture.get_height()) * scale;
        
        float2 coords  = float2(gid) * float2(1.0/w,1.0/h);
        //
        // для всех пикселей за пределами расчета возвращаем чорную точку с прозрачным альфа-каналом
        //
        float  isBoxed = coordsIsInsideBox(coords, float2(regionIn.left,regionIn.bottom), float2(1.0-regionIn.right,1.0-regionIn.top));
        return sampledColor(inTexture,scale,gid) * isBoxed;
    }
    
    inline float4 sampledColor(
                               texture2d<float, access::sample>  inTexture,
                               constant IMPRegion               &regionIn,
                               uint2 gid){
        return sampledColor(inTexture,regionIn,1,gid);
    }

    
    constexpr sampler cornerSampler(address::clamp_to_edge, filter::linear, coord::normalized);
    
    class LineColors {
        
        public:
        
        float3 left;
        float3 center;
        float3 right;
        
        float leftIntensity;
        float centerIntensity;
        float rightIntensity;
                
        METAL_FUNC LineColors() {}
        
        METAL_FUNC LineColors(texture2d<float, access::sample> texture,
                              const float2 texCoord,
                              float y,
                              float radius
                              ) {
            
            float x = radius/float(texture.get_width());
            
            left   = texture.sample(cornerSampler, texCoord + float2(-x,y)).rgb;
            center = texture.sample(cornerSampler, texCoord + float2( 0,y)).rgb;
            right  = texture.sample(cornerSampler, texCoord + float2( x,y)).rgb;
            leftIntensity   = left.r;
            rightIntensity  = right.r;
            centerIntensity = center.r;
        }
        
        METAL_FUNC LineColors(
                              texture2d<float, access::sample> texture,
                              texture2d<float, access::write>  destination,
                              const uint2 gid,
                              int y,
                              int radius
                              ) {
            
            //float x = radius/float(texture.get_width());

            //float2 texCoord = float2(gid)/float2(texture.get_width(),texture.get_height());
            
            int2 g = int2(gid);
            
            left   = IMProcessing::sampledColor(texture, destination, uint2(g + int2(-radius,y))).rgb; //texture.sample(cornerSampler, texCoord + float2(-x,y)).rgb;
            center = IMProcessing::sampledColor(texture, destination, uint2(g + int2(      0,y))).rgb; //texture.sample(cornerSampler, texCoord + float2( 0,y)).rgb;
            right  = IMProcessing::sampledColor(texture, destination, uint2(g + int2( radius,y))).rgb; //texture.sample(cornerSampler, texCoord + float2( x,y)).rgb;

            leftIntensity   = left.r;
            rightIntensity  = right.r;
            centerIntensity = center.r;
        }
        

        
        float leftLuma(){
            return IMProcessing::lum(left);
        }
        float centerLuma(){
            return IMProcessing::lum(center);
        }
        float rightLuma(){
            return IMProcessing::lum(right);
        }
        
    };
    
    class Kernel3x3Colors {
        public:
        LineColors top;
        LineColors mid;
        LineColors bottom;
        
        METAL_FUNC Kernel3x3Colors(texture2d<float, access::sample> texture, const float2 texCoord, float radius){
            float y = radius/float(texture.get_height());
            top    = LineColors(texture,texCoord,-y,radius);
            mid    = LineColors(texture,texCoord, 0,radius);
            bottom = LineColors(texture,texCoord, y,radius);
        };
        
        
        METAL_FUNC Kernel3x3Colors(texture2d<float, access::sample> texture,
                                   texture2d<float, access::write>  destination,
                                   const uint2 gid, int radius){
            //float y = radius/float(texture.get_height());
            top    = LineColors(texture,destination,gid,-radius,radius);
            mid    = LineColors(texture,destination,gid, 0,     radius);
            bottom = LineColors(texture,destination,gid, radius,radius);
        };
        
        float convolveLuma(float3x3 kernelMatrix) {
            return
            kernelMatrix[0].x * top.leftLuma()  +
            kernelMatrix[0].y * top.centerLuma()+
            kernelMatrix[0].z * top.rightLuma() +
            
            kernelMatrix[1].x * mid.leftLuma()  +
            kernelMatrix[1].y * mid.centerLuma()+
            kernelMatrix[1].z * mid.rightLuma() +

            kernelMatrix[2].x * bottom.leftLuma()  +
            kernelMatrix[2].y * bottom.centerLuma()+
            kernelMatrix[2].z * bottom.rightLuma()
            ;
        }
        
        float convolveIntensity(float3x3 kernelMatrix) {
            return
            kernelMatrix[0].x * top.leftIntensity +
            kernelMatrix[0].y * top.centerIntensity+
            kernelMatrix[0].z * top.rightIntensity +
            
            kernelMatrix[1].x * mid.leftIntensity  +
            kernelMatrix[1].y * mid.centerIntensity+
            kernelMatrix[1].z * mid.rightIntensity +
            
            kernelMatrix[2].x * bottom.leftIntensity  +
            kernelMatrix[2].y * bottom.centerIntensity+
            kernelMatrix[2].z * bottom.rightIntensity
            ;
        }

        float3 convolve(float3x3 kernelMatrix) {
            return
            kernelMatrix[0].x * top.left +
            kernelMatrix[0].y * top.center+
            kernelMatrix[0].z * top.right +
            
            kernelMatrix[1].x * mid.left  +
            kernelMatrix[1].y * mid.center+
            kernelMatrix[1].z * mid.right +
            
            kernelMatrix[2].x * bottom.left  +
            kernelMatrix[2].y * bottom.center+
            kernelMatrix[2].z * bottom.right
            ;
        }

    };
    
}

#endif

#endif

#endif /* IMPCommon_metal_h */
