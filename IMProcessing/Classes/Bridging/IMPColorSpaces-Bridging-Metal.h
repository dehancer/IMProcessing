//
//  IMPColorSpaces-Bridging-Metal.h
//  Pods
//
//  Created by denis svinarchuk on 05.05.17.
//
//

#ifndef IMPColorSpaces_Bridging_Metal_h
#define IMPColorSpaces_Bridging_Metal_h

#include "IMPConstants-Bridging-Metal.h"
#include "IMPTypes-Bridging-Metal.h"

//
// IMPRgbSpace  = 0,
// IMPaRgbSpace = 1,
// IMPLabSpace  = 2,
// IMPLchSpace  = 3,
// IMPXyzSpace  = 4,
// IMPDCProfLutSpace = 5,
// IMPHsvSpace  = 6,
// IMPHslSpace  = 7,
// IMPYcbcrHDSpace = 8 // Full-range type
// IMPHspSpace  = 9
//

static constant float2 kIMP_ColorSpaceRanges[10][3] = {
    { (float2){0,1},       (float2){0,1},       (float2){0,1} },       // IMPRgbSpace
    { (float2){0,1},       (float2){0,1},       (float2){0,1} },       // IMPsRgbSpace
    { (float2){0,100},     (float2){-128,127},  (float2){-128,127} },  // IMPLabSpace       https://en.wikipedia.org/wiki/Lab_color_space#Range_of_coordinates
    { (float2){0,100},     (float2){0,141.421}, (float2){0,360} },     // IMPLchSpace
    { (float2){0,95.047},  (float2){0,100},     (float2){0,108.883} }, // IMPXyzSpace       http://www.easyrgb.com/en/math.php#text22
    { (float2){0,6},       (float2){0,1},       (float2){0,1} },       // IMPDCProfLutSpace https://www.ludd.ltu.se/~torger/dcamprof.html
    { (float2){0,1},       (float2){0,1},       (float2){0,1} },       // IMPHsvSpace
    { (float2){0,1},       (float2){0,1},       (float2){0,1} },       // IMPHslSpace
    { (float2){0,255},     (float2){0,255},     (float2){0,255} },     // IMPYcbcrHDSpace   http://www.equasys.de/colorconversion.html
    { (float2){0,1},       (float2){0,1},       (float2){0,1} }        // IMPHspSpace       http://alienryderflex.com/hsp.html
};


static inline float2 IMPgetColorSpaceRange (IMPColorSpaceIndex space, int channel) {
    return kIMP_ColorSpaceRanges[(int)(space)][channel];
}

#define IMPGetColorSpaceRange IMPgetColorSpaceRange

static inline float rgb_gamma_correct(float c, float gamma)
{
//    constexpr float a = 0.055;
//    if(c < 0.0031308)
//        return 12.92*c;
//    else
//        return (1.0+a)*pow(c, 1.0/gamma) - a;
    return pow(c, 1.0/gamma);
}

static inline float3 rgb_gamma_correct_r3 (float3 rgb, float gamma) {
    return (float3){
        rgb_gamma_correct(rgb.x,gamma),
        rgb_gamma_correct(rgb.y,gamma),
        rgb_gamma_correct(rgb.z,gamma)
    };
}


//
// sources: http://www.easyrgb.com/index.php?X=MATH&H=02#text2
//
static inline float lab_ft_forward(float t)
{
    if (t >= 8.85645167903563082e-3) {
        return pow(t, 1.0/3.0);
    } else {
        return t * (841.0/108.0) + 4.0/29.0;
    }
}

static inline float lab_ft_inverse(float t)
{
    if (t >= 0.206896551724137931) {
        return t*t*t;
    } else {
        return 108.0 / 841.0 * (t - 4.0/29.0);
    }
}


//
// dcproflut sources:    https://www.ludd.ltu.se/~torger/dcamprof.html
//
static inline float3 IMPXYZ_2_dcproflut(float3 xyz)
{
    float x = xyz[0], y = xyz[1], z = xyz[2];
    // u' v' and L*
    float up = 4*x / (x + 15*y + 3*z);
    float vp = 9*y / (x + 15*y + 3*z);
    float L = 116*lab_ft_forward(y) - 16;
    if (!isfinite(up)) up = 0;
    if (!isfinite(vp)) vp = 0;
    
    return (float3){ L*0.01, up, vp };
}

static inline float3 IMPdcproflut_2_XYZ(float3 lutspace)
{
    float L = lutspace[0]*100.0, up = lutspace[1], vp = lutspace[2];
    float y = (L + 16)/116;
    y = lab_ft_inverse(y);
    float x = y*9*up / (4*vp);
    float z = y * (12 - 3*up - 20*vp) / (4*vp);
    if (!isfinite(x)) x = 0;
    if (!isfinite(z)) z = 0;
    
    return (float3){ x, y, z };
}

//
// HSV
//
static inline float3 IMPrgb_2_HSV(float3 c)
{
    constexpr float4 K = (float4){0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0};
    float  s = vector_step(c.z, c.y);
    float4 p = vector_mix((float4){c.z, c.y, K.w, K.z}, (float4){c.y, c.z, K.x, K.y}, (float4){s,s,s,s});
    s = vector_step(p.x, c.x);
    float4 q = vector_mix((float4){p.x,p.y,p.w, c.x}, (float4){c.x, p.y,p.z,p.x}, (float4){s,s,s,s});
    float d = q.x - fmin(q.w, q.y);
    constexpr float e = 1.0e-10;
    return (vector_float3){(float)fabs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x};
}

static inline float3 IMPHSV_2_rgb(float3 c)
{
    constexpr float4 K = (float4){1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0};
    float3 p0 = (float3){c.x,c.x,c.x} + (float3){K.x,K.y,K.z} ;// * (float3){6.0,6.0,6.0};
    float3 p1 = vector_fract(p0);
    float3 p2 = p1 * (float3){6.0, 6.0, 6.0} - (float3){K.w,K.w,K.w};
    float3 p = fabs(p2);
    return c.z * vector_mix(K.xxx, vector_clamp(p - K.xxx, 0.0, 1.0), c.y);
}


//
// HSP  http://alienryderflex.com/hsp.html
//
#define  Pr  .299
#define  Pg  .587
#define  Pb  .114

//
//  public domain function by Darel Rex Finley, 2006
//
//  This function expects the passed-in values to be on a scale
//  of 0 to 1, and uses that same scale for the return values.
//
//  See description/examples at alienryderflex.com/hsp.html

static inline float3 RGBtoHSP( float  R, float  G, float  B) {
    
    float H, S, P;
    
    //  Calculate the Perceived brightness.
    P=sqrt(R*R*Pr+G*G*Pg+B*B*Pb);
    
    //  Calculate the Hue and Saturation.  (This part works
    //  the same way as in the HSV/B and HSL systems???.)
    if      (R==G && R==B) {
        H=0.; S=0.;
        return (float3){H,S,P};
    }
    
    if      (R>=G && R>=B) {   //  R is largest
        if    (B>=G) {
            H=6./6.-1./6.*(B-G)/(R-G); S=1.-G/R; }
        else         {
            H=0./6.+1./6.*(G-B)/(R-B); S=1.-B/R; }}
    else if (G>=R && G>=B) {   //  G is largest
        if    (R>=B) {
            H=2./6.-1./6.*(R-B)/(G-B); S=1.-B/G; }
        else         {
            H=2./6.+1./6.*(B-R)/(G-R); S=1.-R/G; }}
    else                   {   //  B is largest
        if    (G>=R) {
            H=4./6.-1./6.*(G-R)/(B-R); S=1.-R/B; }
        else         {
            H=4./6.+1./6.*(R-G)/(B-G); S=1.-G/B;
        }
    }
    
    return (float3){H,S,P};
}


//  public domain function by Darel Rex Finley, 2006
//
//  This function expects the passed-in values to be on a scale
//  of 0 to 1, and uses that same scale for the return values.
//
//  Note that some combinations of HSP, even if in the scale
//  0-1, may return RGB values that exceed a value of 1.  For
//  example, if you pass in the HSP color 0,1,1, the result
//  will be the RGB color 2.037,0,0.
//
//  See description/examples at alienryderflex.com/hsp.html

static inline float3 HSPtoRGB(float H, float  S, float  P) {
    
    float R, G, B;

    float  part, minOverMax=1.-S ;
    
    if (minOverMax>0.) {
        if      ( H<1./6.) {   //  R>G>B
            H= 6.*( H-0./6.); part=1.+H*(1./minOverMax-1.);
            B=P/sqrt(Pr/minOverMax/minOverMax+Pg*part*part+Pb);
            R=(B)/minOverMax; G=(B)+H*((R)-(B)); }
        else if ( H<2./6.) {   //  G>R>B
            H= 6.*(-H+2./6.); part=1.+H*(1./minOverMax-1.);
            B=P/sqrt(Pg/minOverMax/minOverMax+Pr*part*part+Pb);
            G=(B)/minOverMax; R=(B)+H*((G)-(B)); }
        else if ( H<3./6.) {   //  G>B>R
            H= 6.*( H-2./6.); part=1.+H*(1./minOverMax-1.);
            R=P/sqrt(Pg/minOverMax/minOverMax+Pb*part*part+Pr);
            G=(R)/minOverMax; B=(R)+H*((G)-(R)); }
        else if ( H<4./6.) {   //  B>G>R
            H= 6.*(-H+4./6.); part=1.+H*(1./minOverMax-1.);
            R=P/sqrt(Pb/minOverMax/minOverMax+Pg*part*part+Pr);
            B=(R)/minOverMax; G=(R)+H*((B)-(R)); }
        else if ( H<5./6.) {   //  B>R>G
            H= 6.*( H-4./6.); part=1.+H*(1./minOverMax-1.);
            G=P/sqrt(Pb/minOverMax/minOverMax+Pr*part*part+Pg);
            B=(G)/minOverMax; R=(G)+H*((B)-(G)); }
        else               {   //  R>B>G
            H= 6.*(-H+6./6.); part=1.+H*(1./minOverMax-1.);
            G=P/sqrt(Pr/minOverMax/minOverMax+Pb*part*part+Pg);
            R=(G)/minOverMax; B=(G)+H*((R)-(G)); }}
    else {
        if      ( H<1./6.) {   //  R>G>B
            H= 6.*( H-0./6.); R=sqrt(P*P/(Pr+Pg*H*H)); G=(R)*H; B=0.; }
        else if ( H<2./6.) {   //  G>R>B
            H= 6.*(-H+2./6.); G=sqrt(P*P/(Pg+Pr*H*H)); R=(G)*H; B=0.; }
        else if ( H<3./6.) {   //  G>B>R
            H= 6.*( H-2./6.); G=sqrt(P*P/(Pg+Pb*H*H)); B=(G)*H; R=0.; }
        else if ( H<4./6.) {   //  B>G>R
            H= 6.*(-H+4./6.); B=sqrt(P*P/(Pb+Pg*H*H)); G=(B)*H; R=0.; }
        else if ( H<5./6.) {   //  B>R>G
            H= 6.*( H-4./6.); B=sqrt(P*P/(Pb+Pr*H*H)); R=(B)*H; G=0.; }
        else               {   //  R>B>G
            H= 6.*(-H+6./6.); R=sqrt(P*P/(Pr+Pb*H*H)); B=(R)*H; G=0.; }
    }
    
    return (float3){R,G,B};
}

static inline float3 IMPrgb_2_HSP(float3 color) {
    return RGBtoHSP(color.x, color.y, color.z);
}

static inline float3 IMPHSP_2_rgb(float3 hsp) {
    return HSPtoRGB(hsp.x, hsp.y, hsp.z);
}

//
// HSL
//
static inline float3 IMPrgb_2_HSL(float3 color)
{
    
    
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    
#ifdef __METAL_VERSION__
    float _fmin = min(min(color.x, color.y), color.z);    //Min. value of RGB
    float _fmax = max(max(color.x, color.y), color.z);    //Max. value of RGB
#else
    float _fmin = fmin(fmin(color.x, color.y), color.z);    //Min. value of RGB
    float _fmax = fmax(fmax(color.x, color.y), color.z);    //Max. value of RGB
#endif
    float delta = _fmax - _fmin;             //Delta RGB value
    
    hsl.z = vector_clamp((_fmax + _fmin) * 0.5, 0.0, 1.0); // Luminance
    
    if (delta == 0.0)   //This is a gray, no chroma...
    {
        hsl.x = 0.0;	// Hue
        hsl.y = 0.0;	// Saturation
    }
    else                //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (_fmax + _fmin); // Saturation
        else
            hsl.y = delta / (2.0 - _fmax - _fmin); // Saturation
        
        float deltaR = (((_fmax - color.x) / 6.0) + (delta * 0.5)) / delta;
        float deltaG = (((_fmax - color.y) / 6.0) + (delta * 0.5)) / delta;
        float deltaB = (((_fmax - color.z) / 6.0) + (delta * 0.5)) / delta;
        
        if (color.x == _fmax )     hsl.x = deltaB - deltaG; // Hue
        else if (color.y == _fmax) hsl.x = 1.0/3.0 + deltaR - deltaB; // Hue
        else if (color.z == _fmax) hsl.x = 2.0/3.0 + deltaG - deltaR; // Hue
        
        if (hsl.x < 0.0)       hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)  hsl.x -= 1.0; // Hue
    }
    
    return hsl;
}

static inline float hue_2_rgb(float f1, float f2, float hue)
{
    if (hue < 0.0)      hue += 1.0;
    else if (hue > 1.0) hue -= 1.0;
    
    float res;
    
    if ((6.0 * hue) < 1.0)      res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0) res = f2;
    else if ((3.0 * hue) < 2.0) res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else                        res = f1;
    
    res = vector_clamp((float3){res,res,res}, (float3){0.0,0.0,0.0}, (float3){1.0,1.0,1.0}).x;
    
    return res;
}


static inline float3 IMPHSL_2_rgb(float3 hsl)
{
    
    float3 rgb;
    
    if (hsl.y == 0.0) {
        rgb = vector_clamp((float3){hsl.z,hsl.z,hsl.z}, (float3){0.0,0.0,0.0}, (float3){1.0,1.0,1.0}); // Luminance
    }
    else
    {
        float f2;
        
        if (hsl.z < 0.5) f2 = hsl.z * (1.0 + hsl.y);
        else             f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
        
        float f1 = 2.0 * hsl.z - f2;
        
        constexpr float tk = 1.0/3.0;
        
        rgb.x = hue_2_rgb(f1, f2, hsl.x + tk);
        rgb.y = hue_2_rgb(f1, f2, hsl.x);
        rgb.z = hue_2_rgb(f1, f2, hsl.x - tk);
    }
    
    return rgb;
}


//
// XYZ
//
static inline float3 IMPsrgb_2_XYZ(float3 rgb)
{
    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    
    float3 xyz;
    
    xyz.x = r * 41.24 + g * 35.76 + b * 18.05;
    xyz.y = r * 21.26 + g * 71.52 + b * 7.22;
    xyz.z = r * 1.93  + g * 11.92 + b * 95.05;
        
    return xyz;
}

static inline float3 IMPrgb_2_XYZ(float3 rgb)
{
    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    
        if ( r > 0.04045 ) r = pow((( r + 0.055) / 1.055 ), 2.4);
        else               r = r / 12.92;
        
        if ( g > 0.04045 ) g = pow((( g + 0.055) / 1.055 ), 2.4);
        else               g = g / 12.92;;
        
        if ( b > 0.04045 ) b = pow((( b + 0.055) / 1.055 ), 2.4);
        else               b = b / 12.92;
        
    float3 xyz;
    
    xyz.x = r * 41.24 + g * 35.76 + b * 18.05;
    xyz.y = r * 21.26 + g * 71.52 + b * 7.22;
    xyz.z = r * 1.93  + g * 11.92 + b * 95.05;
    
    return xyz;
}


static inline float3 IMPXYZ_2_srgb (float3 xyz){
    
    float var_X = xyz.x / 100.0;       //X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
    float var_Y = xyz.y / 100.0;       //Y from 0 to 100.000
    float var_Z = xyz.z / 100.0;       //Z from 0 to 108.883
    
    float3 rgb;
    
    rgb.x = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986;
    rgb.y = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415;
    rgb.z = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570;
    
    return rgb;
}

static inline float3 IMPXYZ_2_rgb (float3 xyz){
    
    float var_X = xyz.x / 100.0;       //X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
    float var_Y = xyz.y / 100.0;       //Y from 0 to 100.000
    float var_Z = xyz.z / 100.0;       //Z from 0 to 108.883
    
    float3 rgb;
    
    rgb.x = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986;
    rgb.y = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415;
    rgb.z = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570;
    
    if ( rgb.x > 0.0031308 ) rgb.x = 1.055 * pow( rgb.x, ( 1.0 / 2.4 ) ) - 0.055;
    else                     rgb.x = 12.92 * rgb.x;
    
    if ( rgb.y > 0.0031308 ) rgb.y = 1.055 * pow( rgb.y, ( 1.0 / 2.4 ) ) - 0.055;
    else                     rgb.y = 12.92 * rgb.y;
    
    if ( rgb.z > 0.0031308 ) rgb.z = 1.055 * pow( rgb.z, ( 1.0 / 2.4 ) ) - 0.055;
    else                     rgb.z = 12.92 * rgb.z;
    
#ifdef __METAL_VERSION__
    return clamp(rgb, float3(0), float3(1));
#else
    rgb.x = rgb.x < 0 ? 0 : rgb.x;
    rgb.x = rgb.x > 1 ? 1 : rgb.x;

    rgb.y = rgb.y < 0 ? 0 : rgb.y;
    rgb.y = rgb.y > 1 ? 1 : rgb.y;

    rgb.z = rgb.z < 0 ? 0 : rgb.z;
    rgb.z = rgb.z > 1 ? 1 : rgb.z;

    return rgb;
#endif
}



//
// LAB
//
static inline float3 IMPLab_2_XYZ(float3 lab){
    
    float3 xyz;
    
    xyz.y = ( lab.x + 16.0 ) / 116.0;
    xyz.x = lab.y / 500.0 + xyz.y;
    xyz.z = xyz.y - lab.z / 200.0;
    
    if ( pow(xyz.y,3.0) > 0.008856 ) xyz.y = pow(xyz.y,3.0);
    else                             xyz.y = ( xyz.y - 16.0 / 116.0 ) / 7.787;
    
    if ( pow(xyz.x,3.0) > 0.008856 ) xyz.x = pow(xyz.x,3.0);
    else                             xyz.x = ( xyz.x - 16.0 / 116.0 ) / 7.787;
    
    if ( pow(xyz.z,3.0) > 0.008856 ) xyz.z = pow(xyz.z,3.0);
    else                             xyz.z = ( xyz.z - 16.0 / 116.0 ) / 7.787;
    
    xyz.x *= kIMP_Cielab_X;    //     Observer= 2°, Illuminant= D65
    xyz.y *= kIMP_Cielab_Y;
    xyz.z *= kIMP_Cielab_Z;
    
    return xyz;
}

static inline float3 IMPXYZ_2_Lab(float3 xyz)
{
    float var_X = xyz.x / kIMP_Cielab_X;   //   Observer= 2°, Illuminant= D65
    float var_Y = xyz.y / kIMP_Cielab_Y;
    float var_Z = xyz.z / kIMP_Cielab_Z;
    
    float t1 = 1.0/3.0;
    float t2 = 16.0/116.0;
    
    if ( var_X > 0.008856 ) var_X = pow (var_X, t1);
    else                    var_X = ( 7.787 * var_X ) + t2;
    
    if ( var_Y > 0.008856 ) var_Y = pow(var_Y, t1);
    else                    var_Y = ( 7.787 * var_Y ) + t2;
    
    if ( var_Z > 0.008856 ) var_Z = pow(var_Z, t1);
    else                    var_Z = ( 7.787 * var_Z ) + t2;
    
    return (float3){( 116.0 * var_Y ) - 16.0, 500.0 * ( var_X - var_Y ), 200.0 * ( var_Y - var_Z )};
}

//
// Lch
//
static inline float3 IMPLab_2_Lch(float3 xyz) {
    // let l = x
    // let a = y
    // let b = z, lch = xyz
    
    float h = atan2(xyz.z, xyz.y);
    if (h > 0)  { h = ( h / M_PI_F ) * 180; }
#ifdef __METAL_VERSION__
    else        { h = 360 - (  abs( h ) / M_PI_F ) * 180; }
#else
    else        { h = 360 - ( fabs( h ) / M_PI_F ) * 180; }
#endif
    
    float c = sqrt(xyz.y * xyz.y + xyz.z * xyz.z);
    
    return (float3){xyz.x, c, h};
}

static inline float3 IMPLch_2_Lab(float3 xyz) {
    // let l = x
    // let c = y
    // let h = z
    float h = xyz.z *  M_PI_F / 180;
    return (float3){xyz.x, cos(h) * xyz.y, sin(h) * xyz.y};
}

//
// YCbCr
//
// https://msdn.microsoft.com/en-us/library/ff635643.aspx
//

#define yCbCrHD_2_rgb_offset ((float3){0,128,128})

// HD matrix YCbCr: 0-255
#define yCbCrHD_2_rgb_Y  ((float3){ 0.299 * 255,  -0.168935 * 255,  0.499813 * 255})
#define yCbCrHD_2_rgb_Cb ((float3){ 0.587 * 255,  -0.331665 * 255, -0.418531 * 255})
#define yCbCrHD_2_rgb_Cr ((float3){ 0.114 * 255,   0.50059 * 255,  -0.081282 * 255})

#define yCbCrHD_2_rgb_YI  ((float3){0.003921568627451,   0.003921555147863,  0.003921638035507})
#define yCbCrHD_2_rgb_CbI ((float3){-0.0,               -0.001347958833295,  0.006940805571438})
#define yCbCrHD_2_rgb_CrI ((float3){0.005500096251684,  -0.002801572617586, -0.0})

//#define yCbCrHD_2_rgb_Y  ((float3){ 76.2450,  -43.0784,   127.4523 })
//#define yCbCrHD_2_rgb_Cb ((float3){ 149.6850, -84.5746,  -106.7254})
//#define yCbCrHD_2_rgb_Cr ((float3){ 29.0700,   127.6504, -20.7269})

// STD matrix Y:16-235, Cb,Cr:16-240
//#define yCbCr_2_rgb_Y  ((float3){ 65.481,  128.553, 24.966})
//#define yCbCr_2_rgb_Cb ((float3){-37.797, -74.203,  112.0 })
//#define yCbCr_2_rgb_Cr ((float3){ 112.0,  -93.786, -18.214})

// YUV
//#define yuv_2_rgb_Y ((float3){ ( 0.299),  ( 0.587), ( 0.114) })
//#define yuv_2_rgb_U ((float3){ (-0.147),  (-0.289), ( 0.436) })
//#define yuv_2_rgb_V ((float3){ ( 0.615),  (-0.515), (-0.100) })

#define yCbCrHD_M  (float3x3){ yCbCrHD_2_rgb_Y,  yCbCrHD_2_rgb_Cb,  yCbCrHD_2_rgb_Cr }
#define yCbCrHD_MI (float3x3){ yCbCrHD_2_rgb_YI, yCbCrHD_2_rgb_CbI, yCbCrHD_2_rgb_CrI}

static inline float3 IMPrgb_2_YCbCrHD(float3 rgb){
#ifdef __METAL_VERSION__
    return float3(yCbCrHD_M * rgb + yCbCrHD_2_rgb_offset);
#else
    return (matrix_multiply(yCbCrHD_M,rgb) + yCbCrHD_2_rgb_offset);
#endif
}

static inline float3 IMPYCbCrHD_2_rgb(float3 YCbCr){
#ifdef __METAL_VERSION__
    return float3(yCbCrHD_MI * float3(YCbCr - yCbCrHD_2_rgb_offset));
#else
    return matrix_multiply(yCbCrHD_MI,(float3)(YCbCr - yCbCrHD_2_rgb_offset));
#endif
}

//
// Paired Convertors
//

//
// RGB
//
// https://web.archive.org/web/20030212204955/http://www.srgb.com:80/basicsofsrgb.htm
// The linear RGB values are transformed to nonlinear sR'G'B' values as follows:
//
// If  R,G, B <= 0.0031308
// RsRGB = 12.92 * R
// GsRGB = 12.92 * G
// BsRGB = 12.92 * B
//
// else if  R,G, B > 0.0031308
// RsRGB = 1.055 * R(1.0/2.4) - 0.055
// GsRGB = 1.055 * G(1.0/2.4) - 0.055
// BsRGB = 1.055 * B(1.0/2.4) - 0.055
//

static inline float rgb2srgb_transform(float c, float gamma)
{
    constexpr float a = 0.055;
    if(c <= 0.0031308)
        return 12.92*c;
    else
        return (1.0+a)*pow(c, 1.0/gamma) - a;
}

static inline float3 rgb2srgb_transform_r3 (float3 rgb, float gamma) {
    return (float3){
        rgb2srgb_transform(rgb.x,gamma),
        rgb2srgb_transform(rgb.y,gamma),
        rgb2srgb_transform(rgb.z,gamma)
    };
}

static inline float3 IMPrgb2srgb(float3 color){
    return rgb2srgb_transform_r3(color, kIMP_RGB2SRGB_Gamma);
}


static inline float3 IMPrgb2xyz(float3 color){
    return IMPrgb_2_XYZ(color);
}
static inline float3 IMPrgb2hsv(float3 color){
    return IMPrgb_2_HSV(color);
}
static inline float3 IMPrgb2hsl(float3 color){
    return IMPrgb_2_HSL(color);
}
static inline float3 IMPrgb2hsp(float3 color){
    return IMPrgb_2_HSP(color);
}
static inline float3 IMPrgb2lab(float3 color){
    return IMPXYZ_2_Lab(IMPrgb_2_XYZ(color));
}
static inline float3 IMPrgb2lch(float3 color){
    return IMPLab_2_Lch(IMPrgb2lab(color));
}
static inline float3 IMPrgb2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPrgb_2_XYZ(color));
}
static inline float3 IMPrgb2ycbcrHD(float3 color){
    return IMPrgb_2_YCbCrHD(color);
}


//
// Lab
//
static inline float3 IMPlab2xyz(float3 color){
    return IMPLab_2_XYZ(color);
}
static inline float3 IMPlab2lch(float3 color){
    return IMPLab_2_Lch(color);
}
static inline float3 IMPlab2rgb(float3 color){
    return IMPXYZ_2_rgb(IMPlab2xyz(color));
}
static inline float3 IMPlab2hsv(float3 color){
    return IMPrgb2hsv(IMPlab2rgb(color));
}
static inline float3 IMPlab2hsl(float3 color){
    return IMPrgb2hsl(IMPlab2rgb(color));
}
static inline float3 IMPlab2hsp(float3 color){
    return IMPrgb2hsp(IMPlab2rgb(color));
}
static inline float3 IMPlab2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPlab2rgb(color));
}
static inline float3 IMPlab2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPlab2xyz(color));
}

static inline float3 IMPlab2srgb(float3 color){
    return IMPrgb2srgb(IMPlab2rgb(color));
}



//
// XYZ
//
static inline float3 IMPxyz2lab(float3 color){
    return IMPXYZ_2_Lab(color);
}
static inline float3 IMPxyz2lch(float3 color){
    return IMPLab_2_Lch(IMPxyz2lab(color));
}
static inline float3 IMPxyz2rgb(float3 color){
    return IMPXYZ_2_rgb(color);
}
static inline float3 IMPxyz2hsv(float3 color){
    return IMPrgb2hsv(IMPxyz2rgb(color));
}
static inline float3 IMPxyz2hsl(float3 color){
    return IMPrgb2hsl(IMPxyz2rgb(color));
}
static inline float3 IMPxyz2hsp(float3 color){
    return IMPrgb2hsp(IMPxyz2rgb(color));
}
static inline float3 IMPxyz2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPxyz2rgb(color));
}
static inline float3 IMPxyz2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(color);
}

static inline float3 IMPxyz2srgb(float3 color){
    return IMPrgb2srgb(IMPxyz2rgb(color));
}

//
// LCH
//
static inline float3 IMPlch2lab(float3 color){
    return IMPLch_2_Lab(color);
}
static inline float3 IMPlch2rgb(float3 color){
    return IMPlab2rgb(IMPlch2lab(color));
}
static inline float3 IMPlch2hsv(float3 color){
    return IMPrgb2hsv(IMPlch2rgb(color));
}
static inline float3 IMPlch2hsl(float3 color){
    return IMPrgb2hsl(IMPlch2rgb(color));
}
static inline float3 IMPlch2hsp(float3 color){
    return IMPrgb2hsp(IMPlch2rgb(color));
}
static inline float3 IMPlch2xyz(float3 color){
    return IMPlab2xyz(IMPlch2lab(color));
}
static inline float3 IMPlch2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPlch2xyz(color));
}
static inline float3 IMPlch2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPlch2rgb(color));
}

static inline float3 IMPlch2srgb(float3 color){
    return IMPrgb2srgb(IMPlch2rgb(color));
}

//
// HSV
//
static inline float3 IMPhsv2lab(float3 color){
    return IMPrgb2lab(IMPHSV_2_rgb(color));
}
static inline float3 IMPhsv2rgb(float3 color){
    return IMPHSV_2_rgb(color);
}
static inline float3 IMPhsv2lch(float3 color){
    return IMPrgb2lch(IMPhsv2rgb(color));
}
static inline float3 IMPhsv2hsl(float3 color){
    return IMPrgb2hsl(IMPhsv2rgb(color));
}
static inline float3 IMPhsv2hsp(float3 color){
    return IMPrgb2hsp(IMPhsv2rgb(color));
}
static inline float3 IMPhsv2xyz(float3 color){
    return IMPrgb2xyz(IMPhsv2rgb(color));
}
static inline float3 IMPhsv2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPhsv2xyz(color));
}
static inline float3 IMPhsv2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPhsv2rgb(color));
}

static inline float3 IMPhsv2srgb(float3 color){
    return IMPrgb2srgb(IMPhsv2rgb(color));
}

//
// HSL
//
static inline float3 IMPhsl2lab(float3 color){
    return IMPrgb2lab(IMPHSL_2_rgb(color));
}
static inline float3 IMPhsl2rgb(float3 color){
    return IMPHSL_2_rgb(color);
}
static inline float3 IMPhsl2lch(float3 color){
    return IMPrgb2lch(IMPhsl2rgb(color));
}
static inline float3 IMPhsl2hsv(float3 color){
    return IMPrgb2hsv(IMPhsl2rgb(color));
}
static inline float3 IMPhsl2hsp(float3 color){
    return IMPrgb2hsp(IMPhsl2rgb(color));
}
static inline float3 IMPhsl2xyz(float3 color){
    return IMPrgb2xyz(IMPhsl2rgb(color));
}
static inline float3 IMPhsl2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPhsl2xyz(color));
}
static inline float3 IMPhsl2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPhsl2rgb(color));
}

static inline float3 IMPhsl2srgb(float3 color){
    return IMPrgb2srgb(IMPhsl2rgb(color));
}

//
// HSP
//
static inline float3 IMPhsp2lab(float3 color){
    return IMPrgb2lab(IMPHSP_2_rgb(color));
}
static inline float3 IMPhsp2rgb(float3 color){
    return IMPHSP_2_rgb(color);
}
static inline float3 IMPhsp2lch(float3 color){
    return IMPrgb2lch(IMPhsp2rgb(color));
}
static inline float3 IMPhsp2hsv(float3 color){
    return IMPrgb2hsv(IMPhsp2rgb(color));
}
static inline float3 IMPhsp2hsl(float3 color){
    return IMPrgb2hsl(IMPhsp2rgb(color));
}
static inline float3 IMPhsp2xyz(float3 color){
    return IMPrgb2xyz(IMPhsp2rgb(color));
}
static inline float3 IMPhsp2dcproflut(float3 color){
    return IMPXYZ_2_dcproflut(IMPhsp2xyz(color));
}
static inline float3 IMPhsp2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPhsp2rgb(color));
}

static inline float3 IMPhsp2srgb(float3 color){
    return IMPrgb2srgb(IMPhsp2rgb(color));
}



//
// dcproflut
//
static inline float3 IMPdcproflut2rgb(float3 color){
    return IMPXYZ_2_rgb(IMPdcproflut_2_XYZ(color));
}
static inline float3 IMPdcproflut2lab(float3 color){
    return IMPxyz2lab(IMPdcproflut_2_XYZ(color));
}
static inline float3 IMPdcproflut2lch(float3 color){
    return IMPlab2lch(IMPdcproflut2lab(color));
}
static inline float3 IMPdcproflut2hsv(float3 color){
    return IMPrgb2hsv(IMPdcproflut2rgb(color));
}
static inline float3 IMPdcproflut2hsl(float3 color){
    return IMPrgb2hsl(IMPdcproflut2rgb(color));
}
static inline float3 IMPdcproflut2hsp(float3 color){
    return IMPrgb2hsp(IMPdcproflut2rgb(color));
}
static inline float3 IMPdcproflut2xyz(float3 color){
    return IMPdcproflut_2_XYZ(color);
}
static inline float3 IMPdcproflut2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPdcproflut2rgb(color));
}

static inline float3 IMPdcproflut2srgb(float3 color){
    return IMPrgb2srgb(IMPdcproflut2rgb(color));
}


//
// YCbCrHD
//
static inline float3 IMPycbcrHD2rgb(float3 color){
    return IMPYCbCrHD_2_rgb(color);
}
static inline float3 IMPycbcrHD2lab(float3 color){
    return IMPrgb2lab(IMPYCbCrHD_2_rgb(color));
}
static inline float3 IMPycbcrHD2lch(float3 color){
    return IMPlab2lch(IMPycbcrHD2lab(color));
}
static inline float3 IMPycbcrHD2hsv(float3 color){
    return IMPrgb2hsv(IMPycbcrHD2rgb(color));
}
static inline float3 IMPycbcrHD2hsl(float3 color){
    return IMPrgb2hsl(IMPycbcrHD2rgb(color));
}
static inline float3 IMPycbcrHD2hsp(float3 color){
    return IMPrgb2hsp(IMPycbcrHD2rgb(color));
}
static inline float3 IMPycbcrHD2xyz(float3 color){
    return  IMPrgb_2_XYZ(IMPycbcrHD2rgb(color));
}
static inline float3 IMPycbcrHD2dcproflut(float3 color){
    return IMPrgb2dcproflut(IMPycbcrHD2rgb(color));
}

static inline float3 IMPycbcrHD2srgb(float3 color){
    return IMPrgb2srgb(IMPycbcrHD2rgb(color));
}

//
//sRGB
//
//
//
// The nonlinear sR'G'B' values are transformed to linear R,G, B values by:
//
// If  RsRGB,GsRGB, BsRGB <= 0.04045
// R =  RsRGB * 12.92
// G =  GsRGB * 12.92
// B =  BsRGB * 12.92
//
// else if  RsRGB,GsRGB, BsRGB > 0.04045
// R = ((RsRGB + 0.055) / 1.055)^2.4
// G = ((GsRGB + 0.055) / 1.055)^2.4
// B = ((BsRGB + 0.055) / 1.055)^2.4

static inline float srgb2rgb_transform(float c, float gamma)
{
    constexpr float a = 0.055;
    if(c <= 0.04045)
        return c/12.92;
    else
        return pow(((c + a)/(1+a)),gamma);
}

static inline float3 srgb2rgb_transform_r3 (float3 rgb, float gamma) {
    return (float3){
        srgb2rgb_transform(rgb.x,gamma),
        srgb2rgb_transform(rgb.y,gamma),
        srgb2rgb_transform(rgb.z,gamma)
    };
}

static inline float3 IMPsrgb2rgb(float3 color){
    return srgb2rgb_transform_r3(color, kIMP_RGB2SRGB_Gamma);
}

static inline float3 IMPsrgb2lab(float3 color){
    return IMPrgb2lab(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2xyz(float3 color){
    return  IMPrgb2xyz(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2lch(float3 color){
    return IMPrgb2lch(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2hsv(float3 color){
    return IMPrgb2hsv(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2hsl(float3 color){
    return IMPrgb2hsl(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2hsp(float3 color){
    return IMPrgb2hsp(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2dcproflut(float3 color){
    return IMPrgb2dcproflut(IMPsrgb2rgb(color));
}
static inline float3 IMPsrgb2ycbcrHD(float3 color){
    return IMPrgb2ycbcrHD(IMPsrgb2rgb(color));
}



static inline float3 IMPConvertColor(IMPColorSpaceIndex from_cs, IMPColorSpaceIndex to_cs, float3 value) {
    switch (to_cs) {
            
        case IMPRgbSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return value;
                case IMPsRgbSpace:
                    return IMPsrgb2rgb(value);
                case IMPLabSpace:
                    return IMPlab2rgb(value);
                case IMPLchSpace:
                    return IMPlch2rgb(value);
                case IMPHsvSpace:
                    return IMPhsv2rgb(value);
                case IMPHslSpace:
                    return IMPhsl2rgb(value);
                case IMPHspSpace:
                    return IMPhsp2rgb(value);
                case IMPXyzSpace:
                    return IMPxyz2rgb(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2rgb(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2rgb(value);
            }
            break;
            
        case IMPsRgbSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2srgb(value);
                case IMPsRgbSpace:
                    return value;
                case IMPLabSpace:
                    return IMPlab2srgb(value);
                case IMPLchSpace:
                    return IMPlch2srgb(value);
                case IMPHsvSpace:
                    return IMPhsv2srgb(value);
                case IMPHslSpace:
                    return IMPhsl2srgb(value);
                case IMPHspSpace:
                    return IMPhsp2srgb(value);
                case IMPXyzSpace:
                    return IMPxyz2srgb(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2srgb(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2srgb(value);
            }
            break;
          
        case IMPLabSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2lab(value);
                case IMPsRgbSpace:
                    return IMPsrgb2lab(value);
                case IMPLabSpace:
                    return value;
                case IMPLchSpace:
                    return IMPlch2lab(value);
                case IMPHsvSpace:
                    return IMPhsv2lab(value);
                case IMPHslSpace:
                    return IMPhsl2lab(value);
                case IMPHspSpace:
                    return IMPhsp2lab(value);
                case IMPXyzSpace:
                    return IMPxyz2lab(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2lab(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2lab(value);
            }
            
        case IMPDCProfLutSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2dcproflut(value);
                case IMPsRgbSpace:
                    return IMPsrgb2dcproflut(value);
                case IMPLabSpace:
                    return IMPlab2dcproflut(value);
                case IMPLchSpace:
                    return IMPlch2dcproflut(value);
                case IMPHsvSpace:
                    return IMPhsv2dcproflut(value);
                case IMPHslSpace:
                    return IMPhsl2dcproflut(value);
                case IMPHspSpace:
                    return IMPhsp2dcproflut(value);
                case IMPXyzSpace:
                    return IMPxyz2dcproflut(value);
                case IMPDCProfLutSpace:
                    return value;
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2dcproflut(value);
            }
            
        case IMPXyzSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2xyz(value);
                case IMPsRgbSpace:
                    return IMPsrgb2xyz(value);
                case IMPLabSpace:
                    return IMPlab2xyz(value);
                case IMPLchSpace:
                    return IMPlch2xyz(value);
                case IMPHsvSpace:
                    return IMPhsv2xyz(value);
                case IMPHslSpace:
                    return IMPhsl2xyz(value);
                case IMPHspSpace:
                    return IMPhsp2xyz(value);
                case IMPXyzSpace:
                    return value;
                case IMPDCProfLutSpace:
                    return IMPdcproflut2xyz(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2xyz(value);
            }
            
        case IMPHsvSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2hsv(value);
                case IMPsRgbSpace:
                    return IMPsrgb2hsv(value);
                case IMPLabSpace:
                    return IMPlab2hsv(value);
                case IMPLchSpace:
                    return IMPlch2hsv(value);
                case IMPHsvSpace:
                    return value;
                case IMPHslSpace:
                    return IMPhsl2hsv(value);
                case IMPHspSpace:
                    return IMPhsp2hsv(value);
                case IMPXyzSpace:
                    return IMPxyz2hsv(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2hsv(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2hsv(value);
            }
            
        case IMPHslSpace:
        switch (from_cs) {
            case IMPRgbSpace:
            return IMPrgb2hsl(value);
            case IMPsRgbSpace:
            return IMPsrgb2hsl(value);
            case IMPLabSpace:
            return IMPlab2hsl(value);
            case IMPLchSpace:
            return IMPlch2hsl(value);
            case IMPHsvSpace:
            return IMPhsv2hsl(value);
            case IMPHslSpace:
            return value;
            case IMPHspSpace:
            return IMPhsv2hsp(value);
            case IMPXyzSpace:
            return IMPxyz2hsl(value);
            case IMPDCProfLutSpace:
            return IMPdcproflut2hsl(value);
            case IMPYcbcrHDSpace:
            return IMPycbcrHD2hsl(value);
        }
        
        case IMPHspSpace:
        switch (from_cs) {
            case IMPRgbSpace:
            return IMPrgb2hsp(value);
            case IMPsRgbSpace:
            return IMPsrgb2hsp(value);
            case IMPLabSpace:
            return IMPlab2hsp(value);
            case IMPLchSpace:
            return IMPlch2hsp(value);
            case IMPHsvSpace:
            return IMPhsv2hsp(value);
            case IMPHslSpace:
            return IMPhsl2hsp(value);
            case IMPHspSpace:
            return value;
            case IMPXyzSpace:
            return IMPxyz2hsp(value);
            case IMPDCProfLutSpace:
            return IMPdcproflut2hsp(value);
            case IMPYcbcrHDSpace:
            return IMPycbcrHD2hsp(value);
        }
        
        case IMPLchSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2lch(value);
                case IMPsRgbSpace:
                    return IMPsrgb2lch(value);
                case IMPLabSpace:
                    return IMPlab2lch(value);
                case IMPLchSpace:
                    return value;
                case IMPHsvSpace:
                    return IMPhsv2lch(value);
                case IMPHslSpace:
                return IMPhsl2lch(value);
                case IMPHspSpace:
                return IMPhsp2lch(value);
                case IMPXyzSpace:
                    return IMPxyz2lch(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2lch(value);
                case IMPYcbcrHDSpace:
                    return IMPycbcrHD2lch(value);
            }
            
        case IMPYcbcrHDSpace:
            switch (from_cs) {
                case IMPRgbSpace:
                    return IMPrgb2ycbcrHD(value);
                case IMPsRgbSpace:
                    return IMPsrgb2ycbcrHD(value);
                case IMPLabSpace:
                    return IMPlab2ycbcrHD(value);
                case IMPLchSpace:
                    return IMPlch2ycbcrHD(value);
                case IMPHsvSpace:
                    return IMPhsv2ycbcrHD(value);
                case IMPHslSpace:
                return IMPhsl2ycbcrHD(value);
                case IMPHspSpace:
                return IMPhsp2ycbcrHD(value);
                case IMPXyzSpace:
                    return IMPxyz2ycbcrHD(value);
                case IMPDCProfLutSpace:
                    return IMPdcproflut2ycbcrHD(value);
                case IMPYcbcrHDSpace:
                    return value;
            }
    }
    return value;;
}

static inline float3 IMPConvertToNormalizedColor(IMPColorSpaceIndex from, IMPColorSpaceIndex to, float3 rgb) {
    float3 color = IMPConvertColor(from, to, rgb);
    
    float2 xr = IMPgetColorSpaceRange(to,0);
    float2 yr = IMPgetColorSpaceRange(to,1);
    float2 zr = IMPgetColorSpaceRange(to,2);
    
    return (float3){(color.x-xr.x)/(xr.y-xr.x), (color.y-yr.x)/(yr.y-yr.x), (color.z-zr.x)/(zr.y-zr.x)};
}

static inline float3 IMPConvertFromNormalizedColor(IMPColorSpaceIndex from, IMPColorSpaceIndex to, float3 rgb) {
    
    float2 xr = IMPgetColorSpaceRange(from,0);
    float2 yr = IMPgetColorSpaceRange(from,1);
    float2 zr = IMPgetColorSpaceRange(from,2);
    
    float x = rgb.x * (xr.y-xr.x) + xr.x;
    float y = rgb.y * (yr.y-yr.x) + yr.x;
    float z = rgb.z * (zr.y-zr.x) + zr.x;
    
    return IMPConvertColor(from, to, (float3){x,y,z});
    
}

/* $Id: //mondo/camera_raw_main/camera_raw/dng_sdk/source/dng_xy_coord.cpp#3 $ */ 
/* $DateTime: 2016/01/19 15:23:55 $ */
/* $Change: 1059947 $ */
/* $Author: erichan $ */


/******************************************************************************/

static inline float Pin_float (float _min, float x, float _max)
{ 
#ifdef __METAL_VERSION__
    return max (_min, min (x, _max));
#else
     return fmax (_min, fmin (x, _max));
#endif
}

static inline float2 D50_xy_coord () {
    return (float2) {0.3457, 0.3585};
}

static inline float2 IMPxyz2xy (const float3 coord) {
    
    float X = coord [0];
    float Y = coord [1];
    float Z = coord [2];
    
    float total = X + Y + Z;
    
    if (total > 0.0)
    {
        
        return (float2) {X / total, Y / total};
        
    }
    
    return D50_xy_coord ();
    
}

/*****************************************************************************/

static inline float3 IMPxy2xyz (const float2 coord)
{
    
    float2 temp = coord;
    
    // Restrict xy coord to someplace inside the range of real xy coordinates.
    // This prevents math from doing strange things when users specify
    // extreme temperature/tint coordinates.
    
    temp.x = Pin_float (0.000001, temp.x, 0.999999);
    temp.y = Pin_float (0.000001, temp.y, 0.999999);
    
    if (temp.x + temp.y > 0.999999)
    {
        float scale = 0.999999 / (temp.x + temp.y);
        temp.x *= scale;
        temp.y *= scale;
    }
    
    return (float3) {temp.x / temp.y, 1.0, (1.0 - temp.x - temp.y) / temp.y};    
}

/* $Id: //mondo/camera_raw_main/camera_raw/dng_sdk/source/dng_temperature.cpp#3 $ */ 
/* $DateTime: 2016/01/19 15:23:55 $ */
/* $Change: 1059947 $ */
/* $Author: erichan $ */

/*****************************************************************************/

// Scale factor between distances in uv space to a more user friendly "tint"
// parameter.

static constant float kTintScale = -3000.0;

/*****************************************************************************/

// Table from Wyszecki & Stiles, "Color Science", second edition, page 228.

typedef struct
{
    float r;
    float u;
    float v;
    float t;
} ruvt;

static constant ruvt kTempTable [] =
{
    {	0, 0.18006, 0.26352, -0.24341 },
    {  10, 0.18066, 0.26589, -0.25479 },
    {  20, 0.18133, 0.26846, -0.26876 },
    {  30, 0.18208, 0.27119, -0.28539 },
    {  40, 0.18293, 0.27407, -0.30470 },
    {  50, 0.18388, 0.27709, -0.32675 },
    {  60, 0.18494, 0.28021, -0.35156 },
    {  70, 0.18611, 0.28342, -0.37915 },
    {  80, 0.18740, 0.28668, -0.40955 },
    {  90, 0.18880, 0.28997, -0.44278 },
    { 100, 0.19032, 0.29326, -0.47888 },
    { 125, 0.19462, 0.30141, -0.58204 },
    { 150, 0.19962, 0.30921, -0.70471 },
    { 175, 0.20525, 0.31647, -0.84901 },
    { 200, 0.21142, 0.32312, -1.0182 },
    { 225, 0.21807, 0.32909, -1.2168 },
    { 250, 0.22511, 0.33439, -1.4512 },
    { 275, 0.23247, 0.33904, -1.7298 },
    { 300, 0.24010, 0.34308, -2.0637 },
    { 325, 0.24702, 0.34655, -2.4681 },
    { 350, 0.25591, 0.34951, -2.9641 },
    { 375, 0.26400, 0.35200, -3.5814 },
    { 400, 0.27218, 0.35407, -4.3633 },
    { 425, 0.28039, 0.35577, -5.3762 },
    { 450, 0.28863, 0.35714, -6.7262 },
    { 475, 0.29685, 0.35823, -8.5955 },
    { 500, 0.30505, 0.35907, -11.324 },
    { 525, 0.31320, 0.35968, -15.628 },
    { 550, 0.32129, 0.36011, -23.325 },
    { 575, 0.32931, 0.36038, -40.770 },
    { 600, 0.33724, 0.36051, -116.45 }
};

/*****************************************************************************/

static inline float2 IMPxy2tempTint (const float2 xy)
{
    
    float2 tempTint = {0,0};
    
    // Convert to uv space.
    
    float u = 2.0 * xy.x / (1.5 - xy.x + 6.0 * xy.y);
    float v = 3.0 * xy.y / (1.5 - xy.x + 6.0 * xy.y);
    
    // Search for line pair coordinate is between.
    
    float last_dt = 0.0;
    
    float last_dv = 0.0;
    float last_du = 0.0;
    
    for (uint index = 1; index <= 30; index++)
    {
        
        // Convert slope to delta-u and delta-v, with length 1.
        
        float du = 1.0;
        float dv = kTempTable [index] . t;
        
        float len = sqrt (1.0 + dv * dv);
        
        du /= len;
        dv /= len;
        
        // Find delta from black body point to test coordinate.
        
        float uu = u - kTempTable [index] . u;
        float vv = v - kTempTable [index] . v;
        
        // Find distance above or below line.
        
        float dt = - uu * dv + vv * du;
        
        // If below line, we have found line pair.
        
        if (dt <= 0.0 || index == 30)
        {
            
            // Find fractional weight of two lines.
            
            if (dt > 0.0)
                dt = 0.0;
            
            dt = -dt;
            
            float f;
            
            if (index == 1)
            {
                f = 0.0;
            }
            else
            {
                f = dt / (last_dt + dt);
            }
            
            // Interpolate the temperature.
            
            tempTint.x = 1.0E6 / (kTempTable [index - 1] . r * f +
                                    kTempTable [index	 ] . r * (1.0 - f));
            
            // Find delta from black body point to test coordinate.
            
            uu = u - (kTempTable [index - 1] . u * f +
                      kTempTable [index	   ] . u * (1.0 - f));
            
            vv = v - (kTempTable [index - 1] . v * f +
                      kTempTable [index	   ] . v * (1.0 - f));
            
            // Interpolate vectors along slope.
            
            du = du * (1.0 - f) + last_du * f;
            dv = dv * (1.0 - f) + last_dv * f;
            
            len = sqrt (du * du + dv * dv);
            
            du /= len;
            dv /= len;
            
            // Find distance along slope.
            
            tempTint.y = (uu * du + vv * dv) * kTintScale;
            
            break;
            
        }
        
        // Try next line pair.
        
        last_dt = dt;
        
        last_du = du;
        last_dv = dv;        
    }
    
    return tempTint;
}


static inline float2 IMPtempTint2xy (float2 tempTint) {
    
    float2 result = (float2){0,0};
    
    // Find inverse temperature to use as index.
    
    float r = 1.0E6 / tempTint.x;
    
    // Convert tint to offset is uv space.
    
    float offset = tempTint.y * (1.0 / kTintScale);
    
    // Search for line pair containing coordinate.
    
    for (uint index = 0; index <= 29; index++)
    {
        
        if (r < kTempTable [index + 1] . r || index == 29)
        {
            
            // Find relative weight of first line.
            
            float f = (kTempTable [index + 1] . r - r) /
            (kTempTable [index + 1] . r - kTempTable [index] . r);
            
            // Interpolate the black body coordinates.
            
            float u = kTempTable [index	] . u * f +
            kTempTable [index + 1] . u * (1.0 - f);
            
            float v = kTempTable [index	] . v * f +
            kTempTable [index + 1] . v * (1.0 - f);
            
            // Find vectors along slope for each line.
            
            float uu1 = 1.0;
            float vv1 = kTempTable [index] . t;
            
            float uu2 = 1.0;
            float vv2 = kTempTable [index + 1] . t;
            
            float len1 = sqrt (1.0 + vv1 * vv1);
            float len2 = sqrt (1.0 + vv2 * vv2);
            
            uu1 /= len1;
            vv1 /= len1;
            
            uu2 /= len2;
            vv2 /= len2;
            
            // Find vector from black body point.
            
            float uu3 = uu1 * f + uu2 * (1.0 - f);
            float vv3 = vv1 * f + vv2 * (1.0 - f);
            
            float len3 = sqrt (uu3 * uu3 + vv3 * vv3);
            
            uu3 /= len3;
            vv3 /= len3;
            
            // Adjust coordinate along this vector.
            
            u += uu3 * offset;
            v += vv3 * offset;
            
            // Convert to xy coordinates.
            
            result.x = 1.5 * u / (u - 4.0 * v + 2.0);
            result.y =		 v / (u - 4.0 * v + 2.0);
            
            break;            
        } 
        
    }
    
    return result;    
}


/// tempTint-rgb, rgb-tempTint

static constant float3   warmFilter   = (float3)  {0.93, 0.54, 0.0};
static constant float    tintScale    = 0.5226;
//static constant float3   tempTintGray = (float3){122/255,122/255,121/255};

#define RGBtoYIQ_M_R ((float3){0.299,  0.587,  0.114})
#define RGBtoYIQ_M_G ((float3){0.596, -0.274, -0.322})
#define RGBtoYIQ_M_B ((float3){0.212, -0.523,  0.311})

#define YIQtoRGB_M_Y ((float3){1.0,  0.956,  0.621})
#define YIQtoRGB_M_I ((float3){1.0, -0.272, -0.647})
#define YIQtoRGB_M_Q ((float3){1.0, -1.105,  1.702})

#define RGBtoYIQ_M ((float3x3){ RGBtoYIQ_M_R,  RGBtoYIQ_M_G, RGBtoYIQ_M_B })
#define YIQtoRGB_M ((float3x3){ YIQtoRGB_M_Y,  YIQtoRGB_M_I, YIQtoRGB_M_Q })

static inline float3 __temp_processed(float3 rgb){
    
    float3 processed = (float3){
        (rgb.x < 0.5 ? (2.0 * rgb.x * warmFilter.x) : (1.0 - 2.0 * (1.0 - rgb.x) * (1.0 - warmFilter.x))), 
        (rgb.y < 0.5 ? (2.0 * rgb.y * warmFilter.y) : (1.0 - 2.0 * (1.0 - rgb.y) * (1.0 - warmFilter.y))),
        (rgb.z < 0.5 ? (2.0 * rgb.z * warmFilter.z) : (1.0 - 2.0 * (1.0 - rgb.z) * (1.0 - warmFilter.z)))};
    
    return  processed;
}


static inline float2 IMPtempTintFromGray(float3 color, float3 rgbGray){
    
#ifdef __METAL_VERSION__  
    float3 yiq = RGBtoYIQ_M * color;
    float3 yiqGray = RGBtoYIQ_M * rgbGray;
#else
    float3 yiq = matrix_multiply(RGBtoYIQ_M, color);
    float3 yiqGray = matrix_multiply(RGBtoYIQ_M, rgbGray);
#endif

#ifdef __METAL_VERSION__
    //float tint = clamp((yiq.y-yiqGray.y)/tintScale, float(-kIMP_COLOR_TINT), float(kIMP_COLOR_TINT));
#else
    //float tint = vector_clamp((yiq.y-yiqGray.y)/tintScale, -kIMP_COLOR_TINT, kIMP_COLOR_TINT);
#endif
    
    float tint = (yiq.y-yiqGray.y)/tintScale;
    
    yiq.y = vector_clamp(yiq.y - tint*tintScale, -tintScale, tintScale);
    
#ifdef __METAL_VERSION__
    float3 rgb = YIQtoRGB_M * yiq;
#else
    float3 rgb = matrix_multiply(YIQtoRGB_M,yiq);
#endif
    
    float3 processed = __temp_processed(rgb);
    
    float temp = (color.x - rgbGray.x)/(processed.x-rgbGray.x);
    
    temp = temp < 0 ? (temp / 0.0004 + kIMP_COLOR_TEMP) : (temp / 0.00006 + kIMP_COLOR_TEMP);
    
    return (float2){temp,tint};
}

static inline float3 IMPadjustTempTint(float2 tempTint, float3 color){
        
    float temperature = tempTint.x;
    
    temperature = temperature < kIMP_COLOR_TEMP ? 0.0004 * (temperature - kIMP_COLOR_TEMP) : 0.00006 * (temperature - kIMP_COLOR_TEMP);
    
    float tint        = tempTint.y;
    
#ifdef __METAL_VERSION__  
    float3 yiq = RGBtoYIQ_M * color;
#else
    float3 yiq = matrix_multiply(RGBtoYIQ_M,color);
#endif

    //adjusting tint
#ifdef __METAL_VERSION__
    yiq.y = clamp(yiq.y + tint*tintScale, -tintScale, tintScale);
#else
    yiq.y = vector_clamp(yiq.y + tint*tintScale, -tintScale, tintScale);
#endif
    
#ifdef __METAL_VERSION__
    float3 rgb = YIQtoRGB_M * yiq;
#else
    float3 rgb = matrix_multiply(YIQtoRGB_M,yiq);
#endif
    
    //adjusting temperature
    float3 processed = __temp_processed(rgb);
    
    return vector_mix(rgb, processed, temperature);
}

//
//http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_T.html
//

/*
 *      Name:   XYZtoCorColorTemp.c
 *
 *      Author: Bruce Justin Lindbloom
 *
 *      Copyright (c) 2003 Bruce Justin Lindbloom. All rights reserved.
 *
 *      Input:  xyz = pointer to the input array of X, Y and Z color components (in that order).
 *              temp = pointer to where the computed correlated color temperature should be placed.
 *
 *      Output: *temp = correlated color temperature, if successful.
 *                    = unchanged if unsuccessful.
 *
 *      Return: 0 if successful, else -1.
 *
 *      Description:
 *              This is an implementation of Robertson's method of computing the correlated color
 *              temperature of an XYZ color. It can compute correlated color temperatures in the
 *              range [1666.7K, infinity].
 *
 *      Reference:
 *              "Color Science: Concepts and Methods, Quantitative Data and Formulae", Second Edition,
 *              Gunter Wyszecki and W. S. Stiles, John Wiley & Sons, 1982, pp. 227, 228.
 */

//#include <float.h>
//#include <math.h>

/* LERP(a,b,c) = linear interpolation macro, is 'a' when c == 0.0 and 'b' when c == 1.0 */
#define LERP(a,b,c)     (((b) - (a)) * (c) + (a))

typedef struct UVT {
    float  u;
    float  v;
    float  t;
} UVT;

static constant float rt[31] = {       /* reciprocal temperature (K) */
    FLT_MIN,  10.0e-6,  20.0e-6,  30.0e-6,  40.0e-6,  50.0e-6,
    60.0e-6,  70.0e-6,  80.0e-6,  90.0e-6, 100.0e-6, 125.0e-6,
    150.0e-6, 175.0e-6, 200.0e-6, 225.0e-6, 250.0e-6, 275.0e-6,
    300.0e-6, 325.0e-6, 350.0e-6, 375.0e-6, 400.0e-6, 425.0e-6,
    450.0e-6, 475.0e-6, 500.0e-6, 525.0e-6, 550.0e-6, 575.0e-6,
    600.0e-6
};

static constant UVT uvt[31] = {
    {0.18006, 0.26352, -0.24341},
    {0.18066, 0.26589, -0.25479},
    {0.18133, 0.26846, -0.26876},
    {0.18208, 0.27119, -0.28539},
    {0.18293, 0.27407, -0.30470},
    {0.18388, 0.27709, -0.32675},
    {0.18494, 0.28021, -0.35156},
    {0.18611, 0.28342, -0.37915},
    {0.18740, 0.28668, -0.40955},
    {0.18880, 0.28997, -0.44278},
    {0.19032, 0.29326, -0.47888},
    {0.19462, 0.30141, -0.58204},
    {0.19962, 0.30921, -0.70471},
    {0.20525, 0.31647, -0.84901},
    {0.21142, 0.32312, -1.0182},
    {0.21807, 0.32909, -1.2168},
    {0.22511, 0.33439, -1.4512},
    {0.23247, 0.33904, -1.7298},
    {0.24010, 0.34308, -2.0637},
    {0.24792, 0.34655, -2.4681},    /* Note: 0.24792 is a corrected value for the error found in W&S as 0.24702 */
    {0.25591, 0.34951, -2.9641},
    {0.26400, 0.35200, -3.5814},
    {0.27218, 0.35407, -4.3633},
    {0.28039, 0.35577, -5.3762},
    {0.28863, 0.35714, -6.7262},
    {0.29685, 0.35823, -8.5955},
    {0.30505, 0.35907, -11.324},
    {0.31320, 0.35968, -15.628},
    {0.32129, 0.36011, -23.325},
    {0.32931, 0.36038, -40.770},
    {0.33724, 0.36051, -116.45}
};


static inline float IMPXYZtoCorColorTemp(float3 xyz)
{
    float us, vs, p, di = 0.0, dm;
    int i;
    
    
    if ((xyz[0] < 1.0e-20) && (xyz[1] < 1.0e-20) && (xyz[2] < 1.0e-20))
        return(-1);     /* protect against possible divide-by-zero failure */
    
    us = (4.0 * xyz[0]) / (xyz[0] + 15.0 * xyz[1] + 3.0 * xyz[2]);
    vs = (6.0 * xyz[1]) / (xyz[0] + 15.0 * xyz[1] + 3.0 * xyz[2]);
    dm = 0.0;
    
    for (i = 0; i < 31; i++) {
        di = (vs - uvt[i].v) - uvt[i].t * (us - uvt[i].u);
        if ((i > 0) && (((di < 0.0) && (dm >= 0.0)) || ((di >= 0.0) && (dm < 0.0))))
            break;  /* found lines bounding (us, vs) : i-1 and i */
        dm = di;
    }
    if (i == 31)
        return  1666.7;     /* bad XYZ input, color temp would be less than minimum of 1666.7 degrees, or too far towards blue */
    di = di / sqrt(1.0 + uvt[i    ].t * uvt[i    ].t);
    dm = dm / sqrt(1.0 + uvt[i - 1].t * uvt[i - 1].t);
    p = dm / (dm - di);     /* p = interpolation parameter, 0.0 : i-1, 1.0 : i */
    p = 1.0 / (LERP(rt[i - 1], rt[i], p));
    return p;      /* success */
}

#endif /* IMPColorSpaces_Bridging_Metal_h */
