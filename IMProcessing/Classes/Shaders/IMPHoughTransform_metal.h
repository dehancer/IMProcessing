//
//  IMPHuoghTransform_metal.metal
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 13/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#ifndef IMPHuoghTransform_metal_h
#define IMPHuoghTransform_metal_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPCommon_metal.h"
#include "IMPColorSpaces_metal.h"
#include "IMPBlending_metal.h"


#ifdef __cplusplus

inline void houghTransformAtomic(
                                 volatile device   atomic_uint      *accum,
                                 constant uint                      &numrho,
                                 constant uint                      &numangle,
                                 constant float                     &rhoStep,
                                 constant float                     &thetaStep,
                                 constant float                     &minTheta,
                                 uint2 gid
                                 )
{
    float angle = minTheta;
    float irho  = 1/rhoStep;
    for (uint n=0; n<numangle; n++) {
        
        float r = round( float(gid.x) * cos(angle) * irho + float(gid.y) * sin(angle) * irho);
        r += (numrho - 1) / 2;
        angle += thetaStep;
        
        int index = int((n+1) * (numrho+2) + r+1);
        
        atomic_fetch_add_explicit(&accum[index], 1, memory_order_relaxed);
    }
}

kernel void kernel_houghTransformAtomic(
                                        texture2d<float, access::sample>   inTexture   [[texture(0)]],
                                        texture2d<float, access::write>    outTexture  [[texture(1)]],
                                        volatile device   atomic_uint      *accum      [[ buffer(0)]],
                                        constant uint                      &numrho     [[ buffer(1)]],
                                        constant uint                      &numangle   [[ buffer(2)]],
                                        constant float                     &rhoStep    [[ buffer(3)]],
                                        constant float                     &thetaStep  [[ buffer(4)]],
                                        constant float                     &minTheta   [[ buffer(5)]],
                                        constant IMPRegion                 &regionIn   [[ buffer(6)]],
                                        uint2 gid [[thread_position_in_grid]]
                                        )
{
    
    float4 inColor = IMProcessing::sampledColor(inTexture,regionIn,1,gid);
    
    if (inColor.a>0 && inColor.b > 0){
        houghTransformAtomic(accum,numrho,numangle,rhoStep,thetaStep,minTheta,gid);
    }
}

kernel void kernel_houghTransformAtomicOriented(
                                                texture2d<float, access::sample>   inTexture   [[texture(0)]],
                                                texture2d<float, access::write>    outTexture  [[texture(1)]],
                                                volatile device   atomic_uint      *accumHorizontal    [[ buffer(0)]],
                                                volatile device   atomic_uint      *accumVertical      [[ buffer(1)]],
                                                constant uint                      &numrho     [[ buffer(2)]],
                                                constant uint                      &numangle   [[ buffer(3)]],
                                                constant float                     &rhoStep    [[ buffer(4)]],
                                                constant float                     &thetaStep  [[ buffer(5)]],
                                                constant float                     &minTheta   [[ buffer(6)]],
                                                constant IMPRegion                 &regionIn   [[ buffer(7)]],
                                                uint2 gid [[thread_position_in_grid]]
                                                )
{
    
    float4 inColor = IMProcessing::sampledColor(inTexture,regionIn,1,gid);
    
    if (inColor.a>0){
        if ( inColor.g > 0) {
            houghTransformAtomic(accumHorizontal,numrho,numangle,rhoStep,thetaStep,minTheta,gid);
        }
        else if (inColor.b > 0){
            houghTransformAtomic(accumVertical,numrho,numangle,rhoStep,thetaStep,minTheta,gid);
        }
    }
}


/**
 Optimized version
 */
kernel void kernel_houghSpaceLocalMaximumsOriented(
                                                   constant uint      *accumHorizontal     [[ buffer(0)]],
                                                   constant uint      *accumVertical       [[ buffer(1)]],
                                                   device uint2       *maximumsHorizontal  [[ buffer(2)]],
                                                   device uint2       *maximumsVertical    [[ buffer(3)]],
                                                   device atomic_uint *countHorizontal     [[ buffer(4)]],
                                                   device atomic_uint *countVertical       [[ buffer(5)]],
                                                   constant uint      &numrho    [[ buffer(6)]],
                                                   constant uint      &numangle  [[ buffer(7)]],
                                                   constant uint      &threshold [[ buffer(8)]],
                                                   
                                                   uint2 groupSize [[threads_per_threadgroup]],
                                                   uint2 groupId   [[threadgroup_position_in_grid]],
                                                   uint2 gridSize  [[threadgroups_per_grid]],
                                                   uint2 pid [[thread_position_in_grid]]
                                                   
                                                   
                                                   )
{
    
    uint width  = numrho;
    uint height = numangle;
    
    uint gw = (width+gridSize.x-1)/gridSize.x;
    uint gh = (height+gridSize.y-1)/gridSize.y;
    
    for (uint y=0; y<gh; y+=1){
        
        uint ry = y + groupId.y * gh;
        if (ry > height) break;
        
        for (uint x=0; x<gw; x+=1){
            
            uint rx = x + groupId.x * gw;
            if (rx > width) break;
            
            uint base = (ry+1) * (numrho+2) + rx + 1;
            uint bins = accumHorizontal[base];
            
            if(bins > threshold &&
               bins > accumHorizontal[base - 1] && bins >= accumHorizontal[base + 1] &&
               bins > accumHorizontal[base - numrho - 2] && bins >= accumHorizontal[base + numrho + 2] ){
                
                uint index = atomic_fetch_add_explicit(countHorizontal, 1, memory_order_relaxed);
                maximumsHorizontal[index] = uint2(base,bins);
            }
            
            bins = accumVertical[base];
            
            if(bins > threshold &&
               bins > accumVertical[base - 1] && bins >= accumVertical[base + 1] &&
               bins > accumVertical[base - numrho - 2] && bins >= accumVertical[base + numrho + 2] ){
                
                uint index = atomic_fetch_add_explicit(countVertical, 1, memory_order_relaxed);
                maximumsVertical[index] = uint2(base,bins);
            }
        }
    }
}


kernel void kernel_houghSpaceLocalMaximums(
                                           constant uint      *accum     [[ buffer(0)]],
                                           device uint2       *maximums  [[ buffer(1)]],
                                           device atomic_uint *count     [[ buffer(2)]],
                                           constant uint      &numrho    [[ buffer(3)]],
                                           constant uint      &numangle  [[ buffer(4)]],
                                           constant uint      &threshold [[ buffer(5)]],
                                           
                                           uint2 groupSize [[threads_per_threadgroup]],
                                           uint2 groupId   [[threadgroup_position_in_grid]],
                                           uint2 gridSize  [[threadgroups_per_grid]],
                                           uint2 pid [[thread_position_in_grid]]
                                           
                                           
                                           )
{
    
    uint width  = numrho;
    uint height = numangle;
    
    uint gw = (width+gridSize.x-1)/gridSize.x;
    uint gh = (height+gridSize.y-1)/gridSize.y;
    
    for (uint y=0; y<gh; y+=1){
        
        uint ry = y + groupId.y * gh;
        if (ry > height) break;
        
        for (uint x=0; x<gw; x+=1){
            
            uint rx = x + groupId.x * gw;
            if (rx > width) break;
            
            uint base = (ry+1) * (numrho+2) + rx + 1;
            uint bins = accum[base];
            
            //if (bins == 0) { continue; }
            
            if(bins > threshold &&
               bins > accum[base - 1] && bins >= accum[base + 1] &&
               bins > accum[base - numrho - 2] && bins >= accum[base + numrho + 2] ){
                
                uint index = atomic_fetch_add_explicit(count, 1, memory_order_relaxed);
                maximums[index] = uint2(base,bins);
            }
        }
    }
}


/**
 * Релизация kernel-функции MSL с оптимизацией по flow-control
 */
kernel void kernel_bitonicSortUInt2(
                                    device uint2      *array       [[buffer(0)]],
                                    const device uint &stage       [[buffer(1)]],
                                    const device uint &passOfStage [[buffer(2)]],
                                    const device uint &direction   [[buffer(3)]],
                                    uint tid [[thread_index_in_threadgroup]],
                                    uint gid [[threadgroup_position_in_grid]],
                                    uint threads [[threads_per_threadgroup]]
                                    )
{
    uint sortIncreasing = direction;
    
    uint pairDistance = 1 << (stage - passOfStage);
    uint blockWidth   = 2 * pairDistance;
    
    uint globalPosition = threads * gid;
    uint threadId = tid + globalPosition;
    uint leftId = (threadId % pairDistance) + (threadId / pairDistance) * blockWidth;
    
    uint rightId = leftId + pairDistance;
    
    float leftElement  = array[leftId].y;
    float rightElement = array[rightId].y;
    
    uint sameDirectionBlockWidth = 1 << stage;
    
    if((threadId/sameDirectionBlockWidth) % 2 == 1) sortIncreasing = 1 - sortIncreasing;
    
    float greater = mix(leftElement,rightElement,step(leftElement,rightElement));
    float lesser  = mix(leftElement,rightElement,step(rightElement,leftElement));
    
    //
    // Заменяет if/else, но потенциально быстрее в силу того, что не блокирует блок ветвлений.
    // Особенно это хорошо заметно для старых типов GPU (A7, к примеру).
    // Однако, в современных реализациях производительность обработки ветвлений в GPU приблизилась
    // к эквивалентам CPU. Но, в целом, на больших массивах, разница все еще остается заметной.
    //
    array[leftId]  = mix(lesser,greater,step(sortIncreasing,0.5));
    array[rightId] = mix(lesser,greater,step(0.5,float(sortIncreasing)));
    
}


//kernel void kernel_houghSpaceLocalMaximums__(
//                                             constant uint      *accumHorizontal     [[ buffer(0)]],
//                                             constant uint      *accumVertical       [[ buffer(1)]],
//                                             device uint2       *maximumsHorizontal  [[ buffer(2)]],
//                                             device uint2       *maximumsVertical    [[ buffer(3)]],
//                                             device atomic_uint *countHorizontal     [[ buffer(4)]],
//                                             device atomic_uint *countVertical       [[ buffer(5)]],
//                                             constant uint      &numrho    [[ buffer(6)]],
//                                             constant uint      &numangle  [[ buffer(7)]],
//                                             constant uint      &threshold [[ buffer(8)]],
//                                             uint2 tid       [[thread_position_in_threadgroup]],
//                                             uint2 groupSize [[threads_per_threadgroup]]
//
//                                             )
//{
//    for (uint x=0; x<groupSize.x; x++){
//
//        uint rx = x * groupSize.x + tid.x;
//
//        if (rx>=numrho) break;
//
//        for (uint y=0; y<groupSize.y; y++){
//
//            uint ry = y * groupSize.y + tid.y;
//
//            if (ry>=numangle) break;
//
//            uint base = (ry+1) * (numrho+2) + rx + 1;
//
//            uint bins = accumHorizontal[base];
//
//            if (bins != 0) {
//                if(bins > threshold &&
//                   bins > accumHorizontal[base - 1] && bins >= accumHorizontal[base + 1] &&
//                   bins > accumHorizontal[base - numrho - 2] && bins >= accumHorizontal[base + numrho + 2] ){
//
//                    uint index = atomic_fetch_add_explicit(countHorizontal, 1, memory_order_relaxed);
//                    maximumsHorizontal[index] = uint2(base,bins);
//                }
//            }
//
//            bins = accumVertical[base];
//
//            if (bins != 0) {
//                if(bins > threshold &&
//                   bins > accumVertical[base - 1] && bins >= accumVertical[base + 1] &&
//                   bins > accumVertical[base - numrho - 2] && bins >= accumVertical[base + numrho + 2] ){
//
//                    uint index = atomic_fetch_add_explicit(countVertical, 1, memory_order_relaxed);
//                    maximumsVertical[index] = uint2(base,bins);
//                }
//            }
//
//        }
//    }
//}


#endif // __cplusplus
#endif //__METAL_VERSION__
#endif /*IMPHuoghTransform_metal_h*/
