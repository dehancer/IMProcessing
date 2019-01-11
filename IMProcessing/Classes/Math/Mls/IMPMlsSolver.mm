//
//  MSLSolverBridge.m
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#import "IMPMlsSolver.h"
#import "IMPMlsBaseSolver.h"
#import "IMPConstants-Bridging-Metal.h"

@implementation IMPMlsSolver
{
    IMProcessing::IMPMlsBaseSolver *solver;
}

-(instancetype) initWith:(simd_float2)point source:(simd_float2 *)source destination:(simd_float2 *)destination count:(int)count kind:(IMPMlsSolverKind)kind alpha:(float)alpha {
    
    self = [super init];
    
    if (self) {
        solver = new IMProcessing::IMPMlsBaseSolver(point,source,destination,count,kind,alpha);
    }
    
    return self;
}

- (simd_float2) value:(simd_float2)point {
    return solver->value(point);
}

- (void) dealloc {
    delete solver;
}

@end

