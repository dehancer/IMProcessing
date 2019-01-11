//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef IMProcessing_Bridging_Metal_h
#define IMProcessing_Bridging_Metal_h

#include "IMPTypes-Bridging-Metal.h"
#include "IMPConstants-Bridging-Metal.h"
#include "IMPOperations-Bridging-Metal.h"
#include "IMPColorSpaces-Bridging-Metal.h"
#include "IMPHistogramTypes-Bridging-Metal.h"

#ifndef __METAL_VERSION__

#include "IMPExif.h"

#endif

#endif //IMProcessing_Bridging_Metal_h
