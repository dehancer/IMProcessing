//
//  IMProcessing-Bridg-Lib.m
//  Pods
//
//  Created by denis svinarchuk on 03.05.17.
//
//

#import "IMProcessing-Bridging-Lib.h"
#import "IMPColorSpaces-Bridging-Metal.h"

@implementation IMPBridge

+ (float3) rgb2xyz:(float3)color     { return IMPrgb2xyz(color); }
+ (float3) rgb2srgb:(float3)color     { return IMPrgb2srgb(color); }
+ (float3) rgb2lab:(float3)color     { return IMPrgb2lab(color); }
+ (float3) rgb2lch:(float3)color     { return IMPrgb2lch(color); }
+ (float3) rgb2dcproflut:(float3)color     { return IMPrgb2dcproflut(color); }
+ (float3) rgb2hsv:(float3)color     { return IMPrgb2hsv(color); }
+ (float3) rgb2hsl:(float3)color     { return IMPrgb2hsl(color); }
+ (float3) rgb2hsp:(float3)color     { return IMPrgb2hsp(color); }
+ (float3) rgb2ycbcrHD:(float3)color { return IMPrgb2ycbcrHD(color); }

+ (float3) srgb2xyz:(float3)color     { return IMPsrgb2xyz(color); }
+ (float3) srgb2rgb:(float3)color     { return IMPsrgb2rgb(color); }
+ (float3) srgb2lab:(float3)color     { return IMPsrgb2lab(color); }
+ (float3) srgb2lch:(float3)color     { return IMPsrgb2lch(color); }
+ (float3) srgb2dcproflut:(float3)color     { return IMPsrgb2dcproflut(color); }
+ (float3) srgb2hsv:(float3)color     { return IMPsrgb2hsv(color); }
+ (float3) srgb2hsl:(float3)color     { return IMPsrgb2hsl(color); }
+ (float3) srgb2hsp:(float3)color     { return IMPsrgb2hsp(color); }
+ (float3) srgb2ycbcrHD:(float3)color { return IMPsrgb2ycbcrHD(color); }

+ (float3) hsv2rgb:(float3)color     { return IMPhsv2rgb(color); }
+ (float3) hsv2srgb:(float3)color     { return IMPhsv2srgb(color); }
+ (float3) hsv2xyz:(float3)color     { return IMPhsv2xyz(color); }
+ (float3) hsv2lab:(float3)color     { return IMPhsv2lab(color); }
+ (float3) hsv2lch:(float3)color     { return IMPhsv2lch(color); }
+ (float3) hsv2dcproflut:(float3)color     { return IMPhsv2dcproflut(color); }
+ (float3) hsv2ycbcrHD:(float3)color { return IMPhsv2ycbcrHD(color); }
+ (float3) hsv2hsl:(float3)color     { return IMPhsv2hsl(color); }
+ (float3) hsv2hsp:(float3)color     { return IMPhsv2hsp(color); }

+ (float3) hsl2rgb:(float3)color     { return IMPhsl2rgb(color); }
+ (float3) hsl2srgb:(float3)color     { return IMPhsl2srgb(color); }
+ (float3) hsl2hsv:(float3)color     { return IMPhsl2hsv(color); }
+ (float3) hsl2lab:(float3)color     { return IMPhsl2lab(color); }
+ (float3) hsl2lch:(float3)color     { return IMPhsl2lch(color); }
+ (float3) hsl2dcproflut:(float3)color     { return IMPhsl2dcproflut(color); }
+ (float3) hsl2xyz:(float3)color     { return IMPhsl2xyz(color); }
+ (float3) hsl2ycbcrHD:(float3)color { return IMPhsl2ycbcrHD(color); }
+ (float3) hsl2hsp:(float3)color     { return IMPhsl2hsp(color); }

+ (float3) hsp2rgb:(float3)color       { return IMPhsp2rgb(color); }
+ (float3) hsp2srgb:(float3)color      { return IMPhsp2srgb(color); }
+ (float3) hsp2hsv:(float3)color       { return IMPhsp2hsv(color); }
+ (float3) hsp2hsl:(float3)color       { return IMPhsp2hsl(color); }
+ (float3) hsp2lab:(float3)color       { return IMPhsp2lab(color); }
+ (float3) hsp2lch:(float3)color       { return IMPhsp2lch(color); }
+ (float3) hsp2dcproflut:(float3)color { return IMPhsp2dcproflut(color); }
+ (float3) hsp2xyz:(float3)color       { return IMPhsp2xyz(color); }
+ (float3) hsp2ycbcrHD:(float3)color   { return IMPhsp2ycbcrHD(color); }

+ (float3) xyz2rgb:(float3)color     { return IMPxyz2rgb(color); }
+ (float3) xyz2srgb:(float3)color     { return IMPxyz2srgb(color); }
+ (float3) xyz2lab:(float3)color     { return IMPxyz2lab(color); }
+ (float3) xyz2lch:(float3)color     { return IMPxyz2lch(color); }
+ (float3) xyz2dcproflut:(float3)color     { return IMPxyz2dcproflut(color); }
+ (float3) xyz2hsv:(float3)color     { return IMPxyz2hsv(color); }
+ (float3) xyz2hsl:(float3)color     { return IMPxyz2hsl(color); }
+ (float3) xyz2hsp:(float3)color     { return IMPxyz2hsp(color); }
+ (float3) xyz2ycbcrHD:(float3)color { return IMPxyz2ycbcrHD(color); }

+ (float3) lab2rgb:(float3)color     { return IMPlab2rgb(color); }
+ (float3) lab2srgb:(float3)color     { return IMPlab2srgb(color); }
+ (float3) lab2lch:(float3)color     { return IMPlab2lch(color); }
+ (float3) lab2dcproflut:(float3)color     { return IMPlab2dcproflut(color); }
+ (float3) lab2hsv:(float3)color     { return IMPlab2hsv(color); }
+ (float3) lab2hsl:(float3)color     { return IMPlab2hsl(color); }
+ (float3) lab2hsp:(float3)color     { return IMPlab2hsp(color); }
+ (float3) lab2xyz:(float3)color     { return IMPlab2xyz(color); }
+ (float3) lab2ycbcrHD:(float3)color { return IMPlab2ycbcrHD(color); }

+ (float3) dcproflut2rgb:(float3)color     { return IMPdcproflut2rgb(color); }
+ (float3) dcproflut2srgb:(float3)color     { return IMPdcproflut2srgb(color); }
+ (float3) dcproflut2lab:(float3)color     { return IMPdcproflut2lab(color); }
+ (float3) dcproflut2lch:(float3)color     { return IMPdcproflut2lch(color); }
+ (float3) dcproflut2hsv:(float3)color     { return IMPdcproflut2hsv(color); }
+ (float3) dcproflut2hsl:(float3)color     { return IMPdcproflut2hsl(color); }
+ (float3) dcproflut2hsp:(float3)color     { return IMPdcproflut2hsp(color); }
+ (float3) dcproflut2xyz:(float3)color     { return IMPdcproflut2xyz(color); }
+ (float3) dcproflut2ycbcrHD:(float3)color { return IMPdcproflut2ycbcrHD(color); }

+ (float3) lch2rgb:(float3)color     { return IMPlch2rgb(color); }
+ (float3) lch2srgb:(float3)color     { return IMPlch2srgb(color); }
+ (float3) lch2lab:(float3)color     { return IMPlch2lab(color); }
+ (float3) lch2dcproflut:(float3)color     { return IMPlch2dcproflut(color); }
+ (float3) lch2hsv:(float3)color     { return IMPlch2hsv(color); }
+ (float3) lch2hsl:(float3)color     { return IMPlch2hsl(color); }
+ (float3) lch2hsp:(float3)color     { return IMPlch2hsp(color); }
+ (float3) lch2xyz:(float3)color     { return IMPlch2xyz(color); }
+ (float3) lch2ycbcrHD:(float3)color { return IMPlch2ycbcrHD(color); }

+ (float3) ycbcrHD2rgb:(float3)color     { return IMPycbcrHD2rgb(color); }
+ (float3) ycbcrHD2srgb:(float3)color     { return IMPycbcrHD2srgb(color); }
+ (float3) ycbcrHD2lab:(float3)color     { return IMPycbcrHD2lab(color); }
+ (float3) ycbcrHD2lch:(float3)color     { return IMPycbcrHD2lch(color); }
+ (float3) ycbcrHD2dcproflut:(float3)color     { return IMPycbcrHD2dcproflut(color); }
+ (float3) ycbcrHD2hsv:(float3)color     { return IMPycbcrHD2hsv(color); }
+ (float3) ycbcrHD2hsl:(float3)color     { return IMPycbcrHD2hsl(color); }
+ (float3) ycbcrHD2hsp:(float3)color     { return IMPycbcrHD2hsp(color); }
+ (float3) ycbcrHD2xyz:(float3)color     { return IMPycbcrHD2xyz(color); }

+ (float3) convert:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(vector_float3)value {
    return IMPConvertColor(from, to, value);
}

+ (float3) toNormalized:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(vector_float3)value{
    return  IMPConvertToNormalizedColor(from, to, value);
}

+ (float3) fromNormalized:(IMPColorSpaceIndex)from to:(IMPColorSpaceIndex)to value:(vector_float3)value{
    return IMPConvertFromNormalizedColor(from, to, value);
}

+ (float2) xyz2xy:(float3)color {    
    return IMPxyz2xy(color);
}

+ (float3) xy2xyz:(float2)coord {
    return IMPxy2xyz(coord);
}

+ (float2) xy2TempTint:(float2)coord{
    return IMPxy2tempTint(coord);
}

+ (float2) tempTint2xy:(float2)tempTint{
    return IMPtempTint2xy(tempTint);
}

+ (float2) tempTintFor:(float3)color from:(float3)gray {
    return IMPtempTintFromGray(color, gray);
}

+ (float3) adjustTempTint:(float2)tempTint for:(float3)color{
    return IMPadjustTempTint(tempTint, color);
}

+ (float)  xyz2CorColorTemp:(float3)color {
    return IMPXYZtoCorColorTemp(color);
}

@end
