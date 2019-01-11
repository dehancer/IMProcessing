//
//  IMPHistogramTypes.h
//  IMProcessing
//
//  Created by denis svinarchuk on 16.12.15.
//  Copyright © 2015 IMetalling. All rights reserved.
//

#ifndef IMPHistogramTypes_h
#define IMPHistogramTypes_h

#include "IMPConstants-Bridging-Metal.h"


/// @brief Histogram width
#define kIMP_HistogramSize  256

/// @brief Maximum channels histogram may contain
#define kIMP_HistogramMaxChannels 4

/// @brief Interchangeable integral buffer between Metal host implementation and
/// Metal Shading Language shaders
///
typedef struct {
    uint channels[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
}IMPHistogramBuffer;

///  @brief Interchangeable float number buffer
typedef struct {
    float channels[kIMP_HistogramMaxChannels][kIMP_HistogramSize];
}IMPHistogramFloatBuffer;

///  @brief Histogram visualization color options
typedef struct {
    float4 color;
    float  width;
}IMPHistogramLayerComponent;

///  @brief Histogram layer presentation
struct IMPHistogramLayer {
    IMPHistogramLayerComponent components[kIMP_HistogramMaxChannels];
    float4                     backgroundColor;
    bool                       backgroundSource;
    bool                       sample;
    uint                       separatorWidth;
};

///  @brief Color weights clipping preferences
typedef struct{
    float white;
    float black;
    float saturation;
} IMPColorWeightsClipping;


///  @brief Maximum threads launch on GPU to compute Cube histogram
#define kIMP_HistogramCubeThreads      512

///  @brief RGB-Cube resolution: 32x32x32
#define kIMP_HistogramCubeResolution   32
///  @brief RGB-Cube histgjram linear size
#define kIMP_HistogramCubeSize         32768
///  @brief RGB-Cube rgb index in the linear histogram array
#define kIMP_HistogramCubeIndex(rgb) uint(rgb.r+rgb.g*kIMP_HistogramCubeResolution+rgb.b*kIMP_HistogramCubeResolution*kIMP_HistogramCubeResolution)

///  @brief Kernel-side Cube of one cell presentation.
typedef struct {
    ///  @brief All color counts in the cell
    uint count;
    ///  @brief Total red color volume in the cell
    uint reds;
    ///  @brief Total green color volume in the cell
    uint greens;
    ///  @brief Total blue color volume in the cell
    uint blues;
} IMPHistogramCubeCellUint;

///  @brief Host-side Cube of one cell presentation.
typedef struct {
    ///  @brief All color counts in the cell
    float count;
    ///  @brief Total red color volume in the cell
    float reds;
    ///  @brief Total green color volume in the cell
    float greens;
    ///  @brief Total blue color volume in the cell
    float blues;
} IMPHistogramCubeCell;

///  @brief Completed RGB-Cube buffer
typedef struct {
    IMPHistogramCubeCellUint cells[kIMP_HistogramCubeSize];
}IMPHistogramCubeBuffer;

///  @brief Clip shadows/highlights during statistic computaion
typedef struct {
    float3 shadows;
    float3 highlights;
}IMPHistogramCubeClipping;

typedef struct{
    float4 color;
}IMPPaletteBuffer;

typedef struct{
    float4     backgroundColor;
    bool       backgroundSource;
}IMPPaletteLayerBuffer;


#endif /* IMPHistogramTypes_h */
