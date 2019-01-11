//
//  IMPTpsSolverCommon.h
//  IMProcessing
//
//  Created by denn on 07.08.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

#ifndef IMPTpsSolverCommon_h
#define IMPTpsSolverCommon_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>

using namespace metal;

#include "IMPSwift-Bridging-Metal.h"
#include "IMPFlowControl_metal.h"
#include "IMPConstants_metal.h"

#else

#include <simd/simd.h>

#endif

#ifdef __cplusplus

namespace IMProcessing
{

    template<typename T> static inline T tpsBaseFunction(const T r) {
        if ( r == 0.0 ) { return 0.0; }
        else {return r*r * log(r*r); }
    }
    
    /*! @abstract A vector of three 32-bit floating-point numbers.
     *  @description In C++ and Metal, this type is also available as
     *  simd::float3. Note that vectors of this type are padded to have the same
     *  size and alignment as simd_float4.
     *
     *  typedef __attribute__((__ext_vector_type__(3))) float simd_float3;
     *
     * so, the sizeof(V)/sizeof(F) !== real size of vector!
     */
    template<typename V, typename T, int size>
    static inline V tpsValue(
                             const V   point,
#ifdef __METAL_VERSION__
                             constant V   *weights,
                             constant V   *q,
#else
                             const V   *weights,
                             const V   *q,
#endif
                             const int count) {
        
        if (weights == 0 || count < size) return point;
        
        V z(0);
        
        for(int j = 0; j<size; j++) {

            T vt = weights[0][j];

            for(int r = 0; r<size; r++) {
                vt += weights[r+1][j] * point[r];
            }

            for(int r = 0; r<count; r++) {
                vt += weights[r+1+size][j] * tpsBaseFunction<T>(distance(q[r],point));
            }

            z[j] = vt;
        }
        
        return z;
    }
}

#endif

#endif /* IMPTpsSolverCommon_h */
