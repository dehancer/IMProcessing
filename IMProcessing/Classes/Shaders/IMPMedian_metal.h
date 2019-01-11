//
//  IMPMedian_metal.html
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 23/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPMedian_metal_h
#define IMPMedian_metal_h

#ifdef __METAL_VERSION__

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"

using namespace metal;

#ifdef __cplusplus


#define s2(a, b)                temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)            s2(a, b); s2(a, c);
#define mx3(a, b, c)            s2(b, c); s2(a, c);

#define mnmx3(a, b, c)          mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)       s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)    s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges

//
// http://alienryderflex.com/quicksort/
//
//  quickSort
//
//  This public-domain C implementation by Darel Rex Finley.
//
//  * This function assumes it is called with valid parameters.
//
//  * Example calls:
//    quickSort(&myArray[0],5); // sorts elements 0, 1, 2, 3, and 4
//    quickSort(&myArray[3],5); // sorts elements 3, 4, 5, 6, and 7

#define QSORT_MAX_LEVELS  300
#define QSORT_MAX_SIZE    64

template<typename T> METAL_FUNC void quickSort(thread vec<T, 3> *arr, int elements) {
    
    int beg[QSORT_MAX_LEVELS], end[QSORT_MAX_LEVELS], i=0, L, R, swap ;
    vec<T, 3> piv;
    
    beg[0]=0; end[0]=elements;
    
    while (i>=0) {
        L=beg[i]; R=end[i]-1;
        if (L<R) {
            piv=arr[L];
            while (L<R) {
                while (IMProcessing::lum(arr[R])>=IMProcessing::lum(piv) && L<R) R--; if (L<R) arr[L++]=arr[R];
                while (IMProcessing::lum(arr[L])<=IMProcessing::lum(piv) && L<R) L++; if (L<R) arr[R--]=arr[L]; }
            arr[L]=piv; beg[i+1]=L+1; end[i+1]=end[i]; end[i++]=L;
            if (end[i]-beg[i]>end[i-1]-beg[i-1]) {
                swap=beg[i]; beg[i]=beg[i-1]; beg[i-1]=swap;
                swap=end[i]; end[i]=end[i-1]; end[i-1]=swap; }}
        else {
            i--; }
    }
}


kernel void kernel_median3x3(texture2d<float, access::sample> source  [[texture(0)]],
                          texture2d<float, access::write> destination [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float2 texelSize = float2(1)/float2(source.get_width(),source.get_height());
    float2 texCoord  = float2(gid)*texelSize;
    
    IMProcessing::Kernel3x3Colors corner(source,texCoord,1);
    
    
    float3 v[6];
    
    v[0] = corner.bottom.left;
    v[1] = corner.top.right;
    v[2] = corner.top.left;
    v[3] = corner.bottom.right;
    v[4] = corner.mid.left;
    v[5] = corner.mid.right;
    float3 temp;
    
    mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
    
    v[5] = corner.bottom.center;
    
    mnmx5(v[1], v[2], v[3], v[4], v[5]);
    
    v[5] = corner.top.center;
    
    mnmx4(v[2], v[3], v[4], v[5]);
    
    v[5] = corner.mid.center;
    
    mnmx3(v[3], v[4], v[5]);
    
    float4 result = float4(v[4], 1.0);
    
    destination.write(result, gid);
}

kernel void kernel_median(texture2d<float, access::sample> source      [[texture(0)]],
                           texture2d<float, access::write> destination [[texture(1)]],
                           constant uint                   &dimensions  [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{

    //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    thread float3 array[QSORT_MAX_SIZE];

    uint size = min(uint(dimensions),uint(QSORT_MAX_SIZE));
    
    float3 center = IMProcessing::sampledColor(source,destination,gid).rgb;

    float2 texelSize = float2(1)/float2(source.get_width(),source.get_height());
    float2 texCoord  = float2(gid)*texelSize;
    
    array[0] = center;
    
    uint mediani = size/2;
    uint index   = 0;
    for(uint x = 1; x<=mediani; x+=1){
        for(uint y = 1; y<=mediani; y+=1){
            float3 colorNeg = source.sample(IMProcessing::baseSampler, (texCoord - texelSize * float2(x,y))).rgb;
            float3 colorPos = source.sample(IMProcessing::baseSampler, (texCoord + texelSize * float2(x,y))).rgb;
            array[index] = colorNeg; index++;
            array[index] = colorPos; index++;
        }
    }
    
    quickSort(array, size);
    
    float3 median = array[mediani];
    
    destination.write(float4(median,1), gid);
}


kernel void kernel_median2pass(texture2d<float, access::sample> source      [[texture(0)]],
                               texture2d<float, access::write> destination  [[texture(1)]],
                               constant float2                 &texelSize   [[buffer(0)]],
                               constant uint                   &dimensions  [[buffer(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    
    //constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    thread float3 array[QSORT_MAX_SIZE];
    
    uint size = min(uint(dimensions),uint(QSORT_MAX_SIZE));
    
    float3 center    = IMProcessing::sampledColor(source,destination,gid).rgb;
    float2 texCoord = float2(gid)/float2(destination.get_width(),destination.get_height());
    
    array[0] = center;
    
    uint mediani = size/2;
    uint index   = 0;
    for(uint x = 1; x<=mediani; x+=1){
        float3 colorNeg = source.sample(IMProcessing::baseSampler, (texCoord - texelSize * float2(x))).rgb;
        float3 colorPos = source.sample(IMProcessing::baseSampler, (texCoord + texelSize * float2(x))).rgb;
        array[index] = colorNeg; index++;
        array[index] = colorPos; index++;
    }
    
    quickSort(array, size);
    
    float3 median = array[mediani];
    
    destination.write(float4(median,1), gid);
}

#endif

#endif

#endif /* IMPMedian_metal_h */


