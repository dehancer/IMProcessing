//
//  MSLSolverBridge.h
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "IMPMlsSolverCommon.h"
#import <simd/simd.h>

@interface IMPMlsSolver : NSObject
- (instancetype) initWith:(simd_float2)point 
                  source:(simd_float2*)source 
             destination:(simd_float2*)destination 
                   count:(int)count 
                    kind:(IMPMlsSolverKind)kind
                    alpha:(float)alpha;
- (simd_float2) value:(simd_float2)point;
@end
