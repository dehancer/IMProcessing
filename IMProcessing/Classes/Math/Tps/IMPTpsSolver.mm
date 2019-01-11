//
//  IMPTPSSolver.m
//  IMProcessing
//
//  Created by denn on 19.07.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

#import "IMPTpsBaseSolver.h"
#import "IMPTpsSolver.h"
#import "IMPConstants-Bridging-Metal.h"

@implementation IMPTpsSolver2D
{
    IMProcessing::IMPTpsBaseSolver<simd_float2,float,2> *solver;
}

-(instancetype) initWith:(simd_float2 *)source destination:(simd_float2 *)destination count:(int)count lambda:(float)lambda {
    
    self = [super init];
    
    if (self) {
        solver = new IMProcessing::IMPTpsBaseSolver<simd_float2,float,2>(source, destination, count, lambda);
    }
    
    return self;
}

- (const simd_float2 *_Nonnull) weights {
    return solver->getWeights();
}

- (size_t) weightsCount {
    return solver->getWeightsCount();
}

- (simd_float2) value:(simd_float2)point {
    return solver->value(point);
}

- (void) dealloc {
    delete solver;
}
@end


@implementation IMPTpsSolver3D
{
    IMProcessing::IMPTpsBaseSolver<simd_float3,float,3> *solver;
}

-(instancetype) initWith:(simd_float3 *)source destination:(simd_float3 *)destination count:(int)count lambda:(float)lambda {
        
    self = [super init];
    
    if (self) {
        solver = new IMProcessing::IMPTpsBaseSolver<simd_float3,float,3>(source, destination, count, lambda);
    }
    
    return self;
}

- (const simd_float3 *_Nonnull) weights {
    return solver->getWeights();
}

- (size_t) weightsCount {
    return solver->getWeightsCount();
}

- (simd_float3) value:(simd_float3)point {
    return solver->value(point);
}

- (void) dealloc {
   delete solver;
}
@end
