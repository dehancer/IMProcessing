//
//  IMPTPSSolver.hpp
//  IMProcessing
//
//  Created by denn on 19.07.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

#ifndef ___IMPTPSBASESolver_hpp
#define ___IMPTPSBASESolver_hpp

#ifdef __cplusplus

#ifndef __METAL_VERSION__
#include <Foundation/Foundation.h>
#include <Accelerate/Accelerate.h>
typedef __CLPK_integer LAInt;
#endif


#include "IMPMatrixExtension.h"
#include "IMPTpsSolverCommon.h"
#include "IMPConstants-Bridging-Metal.h"

#include <simd/simd.h>

using namespace simd;

namespace IMProcessing {
    
#ifndef __METAL_VERSION__
    /* Auxiliary routine: printing a matrix */
    void print_matrix(const char* desc, __CLPK_integer m, __CLPK_integer n, float* a, __CLPK_integer lda ) {
        __CLPK_integer i, j;
        printf( "\n %s\n", desc );
        for( i = 0; i < m; i++ ) {
            for( j = 0; j < n; j++ ) printf( " %6.2f", a[i+j*lda] );
            printf( "\n" );
        }
    }
#endif
    
    /*! @abstract A vector of three 32-bit floating-point numbers.
     *  @description In C++ and Metal, this type is also available as
     *  simd::float3. Note that vectors of this type are padded to have the same
     *  size and alignment as simd_float4.
     *
     *  typedef __attribute__((__ext_vector_type__(3))) float simd_float3;
     *
     * so, the sizeof(V)/sizeof(F) !== real size of vector!
     */
    
    template<typename V, typename F, int size> class IMPTpsBaseSolver{
        
        public:
        
        /**
         Create Thin Plate Spline solver
         
         @param p source control points
         @param q destination control points
         @param count count of control points
         @param lambda degree of deformations
         */
        IMPTpsBaseSolver(
#ifndef __METAL_VERSION__
                     const V *p,
                     const V *q,
#else
                     constant V *p,
                     constant V *q,
#endif
                     const int count,
                     const F lambda = 1.0):
        alpha_(0),
        lambda_(lambda),
        count_(count),
        p_(p), q_(q),
        weights_(0),
        size_(size),
        rows_(count_+size_+1),
        columns_(count_+size_+1)
        {
#ifndef __METAL_VERSION__
            
            assert( (typeid(F) == typeid(float)) || (typeid(F) == typeid(double)));
            
            weights_ = solver();
            
#endif
        }
        
        /**
         Return a new position for the source point
         
         @param point source point
         @return new position
         */
        V value(V point) {
            if (count_ <= 0) return point;
            return tpsValue<V,F,size>(point, weights_, q_, count_);
        }
        
        const V* getWeights() {
            return weights_;
        }

        size_t getWeightsCount() {
            return rows_;
        }

        
        ~IMPTpsBaseSolver() {
#ifndef __METAL_VERSION__
            if (weights_)
            free((void *)weights_);
#endif
        }
        
        private:
        
        F   lambda_;
        F   alpha_;
        int size_;
        int count_;
        
        int rows_;
        int columns_;
        
#ifndef __METAL_VERSION__
        const V *weights_;
#else
        constant V *weights_;
#endif
        
#ifndef __METAL_VERSION__
        const V *p_;
        const V *q_;
#else
        constant V *p_;
        constant V *q_;
#endif
        
#ifndef __METAL_VERSION__
        
        //
        // this version soves only in CPU context
        //
        void prepareA(F *A) {
            memset(A,0,rows_*columns_*sizeof(F));

            int ks = size_ +1;
            
            alpha_ = 0;
            
            for(int r=0; r<count_; r++) {
                for(int c=1; c<ks; c++) {
                    A[r*columns_+c] = p_[r][c-1];
                }
                for(int c=0; c<count_; c++) {
                    F elen = distance(p_[r],p_[c]);
                    A[r*columns_+c+ks] = tpsBaseFunction(elen);
                    alpha_ += elen * 2;
                }
            }
            
            alpha_ /= (F)(count_*count_);
            alpha_ = alpha_*alpha_;
            
            for(int r=0; r<count_; r++) {
                A[r*columns_ + r+ks] = alpha_ * lambda_;
            }
            
            for(int c=0; c<count_; c++) {
                for(int r=0; r<size_; r++) {
                    A[(count_+1+r)*columns_ + c+ks] = p_[c][r];
                }
                A[c*columns_ + 0] = 1;
                A[count_*columns_ + c+ks] = 1;
            }
        }
        
        void prepareB(F *B) {
            
            memset(B,0,rows_*size_*sizeof(F));
            
            for (int i=0; i<size_; i++) {
                for (int j=0; j<count_; j++) {
                    B[j+i*rows_] = q_[j][i];
                }
            }
        }
        
        V *solver() {
            
            V *out = (V*)(malloc(sizeof(V)*(rows_)));
            
            F  A[rows_*columns_];
            prepareA(A);
            
            F B[rows_*size_];
            prepareB(B);
            
            solve_Ax_B(A, B, columns_, rows_);
            
            for (int c=0; c<size_; c++) {
                for (int r=0; r<rows_; r++){
                    out[r][c] = B[r+c*rows_];
                }
            }
            
            return out;
        }
        
        void solve_Ax_B(const F *A, F *B, int columns, int rows) {
            
            LAInt numberOfEquations = (LAInt)(rows);
            LAInt columnsInA        = (LAInt)(columns);
            LAInt elementsInB       = (LAInt)(rows);
            LAInt bSolutionCount    = (LAInt)(size_);
            
            LAInt outputOk = 0;
            LAInt pivot[rows];
            
            memset(pivot,0,sizeof(pivot));
            
            __CLPK_real _A[rows_*columns_];
            vDSP_mtrans(A, 1, _A, 1, vDSP_Length(rows), vDSP_Length(columns));
            
            if (typeid(F) == typeid(float)) {
                sgesv_(&numberOfEquations, &bSolutionCount,
                       (__CLPK_real *)_A, &columnsInA,
                       pivot,
                       (__CLPK_real *)B, &elementsInB,
                       &outputOk);
            }
            else if (typeid(F) == typeid(double)) {
                dgesv_(&numberOfEquations, &bSolutionCount,
                       (__CLPK_doublereal *)_A, &columnsInA,
                       pivot,
                       (__CLPK_doublereal *)B, &elementsInB,
                       &outputOk);
            }
        }
#endif
    };
}

#endif /* __cplusplus */

#endif /* ___IMPTPSBASESolver_hpp */
