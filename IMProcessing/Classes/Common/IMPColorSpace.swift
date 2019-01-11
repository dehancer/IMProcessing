//
//  IMPColorSpace.swift
//  Pods
//
//  Created by Denis Svinarchuk on 03/05/2017.
//
//

import Cocoa
#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import simd
import Metal

private var __colorSpaceList = [IMPColorSpace]()

public enum IMPColorSpace:String {
    
    public static let rgbIndex  = Int(IMPRgbSpace.rawValue)
    public static let srgbIndex = Int(IMPsRgbSpace.rawValue)
    public static let labIndex  = Int(IMPLabSpace.rawValue)
    public static let lchIndex  = Int(IMPLchSpace.rawValue)
    public static let xyzIndex  = Int(IMPXyzSpace.rawValue)
    public static let dcproflutIndex  = Int(IMPDCProfLutSpace.rawValue)
    public static let hsvIndex  = Int(IMPHsvSpace.rawValue)
    public static let hslIndex  = Int(IMPHslSpace.rawValue)
    public static let ycbcrHDIndex = Int(IMPYcbcrHDSpace.rawValue)
    public static let hspIndex  = Int(IMPHspSpace.rawValue)
    
    public static let spacesCount = 9
    
    case rgb  = "RGB"
    case srgb = "sRGB"
    case lab  = "L*a*b"
    case lch  = "L*c*h"
    case xyz  = "XYZ"
    case dcproflut  = "DCProf Lut"
    case hsv  = "HSV"
    case hsl  = "HSL"
    case hsp  = "HSP"
    case ycbcrHD = "YCbCr/HD"
    
    public init(index:Int) {
        switch index {
        case IMPColorSpace.rgbIndex:  self = .rgb  // 0
        case IMPColorSpace.srgbIndex: self = .srgb  // 0
        case IMPColorSpace.labIndex:  self = .lab
        case IMPColorSpace.lchIndex:  self = .lch
        case IMPColorSpace.hsvIndex:  self = .hsv
        case IMPColorSpace.hslIndex:  self = .hsl
        case IMPColorSpace.xyzIndex:  self = .xyz
        case IMPColorSpace.dcproflutIndex:  self = .dcproflut
        case IMPColorSpace.ycbcrHDIndex:  self = .ycbcrHD
        case IMPColorSpace.hspIndex:  self = .hsp
        default:
            self = .rgb
        }
    }
    
    public var index:Int {
        get {
            switch self {
            case .rgb: return IMPColorSpace.rgbIndex
            case .srgb:return IMPColorSpace.srgbIndex
            case .lab: return IMPColorSpace.labIndex
            case .lch: return IMPColorSpace.lchIndex
            case .hsv: return IMPColorSpace.hsvIndex
            case .hsl: return IMPColorSpace.hslIndex
            case .xyz: return IMPColorSpace.xyzIndex
            case .dcproflut: return IMPColorSpace.dcproflutIndex
            case .ycbcrHD: return IMPColorSpace.ycbcrHDIndex
            case .hsp: return IMPColorSpace.hspIndex
            }
        }
    }
    
    public static var list:[IMPColorSpace] {
        get{
            if __colorSpaceList.count == 0 {
                for i in 0...IMPColorSpace.spacesCount {
                    __colorSpaceList.append(IMPColorSpace(index: i))
                }
            }
            return __colorSpaceList
        }
    }
    
    public var channelNames: [String] {
        switch self {
        case .rgb:  return ["R","G", "B"]
        case .srgb: return ["R","G", "B"]
        case .lab:  return ["L*","a*", "b*"]
        case .lch:  return ["L*","c*", "h"]
        case .hsv:  return ["H","S", "V"]
        case .hsl:  return ["H","S", "L"]
        case .dcproflut:  return ["L","u", "v"]
        case .xyz:  return ["X","Y", "Z"]
        case .ycbcrHD: return ["Y","Cb", "Cr"]
        case .hsp: return ["H","S", "P"]
        }
    }
    
    public var channelDescription: [String] {
        switch self {
        case .rgb:  return ["Red","Green", "Blue"]
        case .srgb: return ["Red","Green", "Blue"]
        case .lab:  return ["Lightness","a-channel", "b-channel"]
        case .lch:  return ["Lightness","Chroma", "Hue"]
        case .hsv:  return ["Hue","Saturation", "Value"]
        case .hsl:  return ["Hue","Saturation", "Luminosity"]
        case .dcproflut:  return ["Lightness","u-channel", "v-channel"]
        case .xyz:  return ["X-channel","Y-channel", "Z-channel"]
        case .ycbcrHD: return ["Y-channel","Cb-channel", "Cr-channel"]
        case .hsp: return ["Hue","Saturation", "Perceived brightness"]
        }
    }
    
    public var channelColors:[NSColor] {
        switch self {
        case .rgb: return [NSColor.red,    NSColor.green,  NSColor.blue]
        case .srgb:return [NSColor.red,    NSColor.green,  NSColor.blue]
        case .lab: return [NSColor.white,  NSColor.orange, NSColor.blue]
        case .lch: return [NSColor.white,  NSColor.orange, NSColor.blue]
        case .hsv: return [NSColor.magenta,NSColor.red,    NSColor.white]
        case .hsl: return [NSColor.magenta,NSColor.red,    NSColor.white]
        case .hsp: return [NSColor.magenta,NSColor.red,    NSColor.white]
        case .dcproflut: return [NSColor.white,  NSColor.orange, NSColor.blue]
        case .xyz: return [NSColor.red,    NSColor.green,  NSColor.blue]
        case .ycbcrHD: return [NSColor.red,NSColor.green,  NSColor.blue]
        }
    }
    
    public var channelRanges:[float2] {
        let ranges = Array(Mirror.init(reflecting: kIMP_ColorSpaceRanges).children)[self.index].value as! (float2,float2,float2)
        return [ranges.0, ranges.1, ranges.2]
    }
    
    public func from(_ space: IMPColorSpace, value: float3) -> float3 {
        return convert(from: space, to: self, value: value)
    }
    
    public func to(_ space: IMPColorSpace, value: float3) -> float3 {
        return convert(from: self, to: space, value: value)
    }
    
    public func toNormalized(_ space: IMPColorSpace, value: float3) -> float3 {
        return toNormalized(from: self, to: space, value: value)
    }

    public func fromNormalized(_ space: IMPColorSpace, value: float3) -> float3 {
        return fromNormalized(from: space, to: self, value: value)
    }
    
    static let rgb2xyzM = float3x3(rows:[
        float3(0.49,    0.31,   0.2)/float3(0.17697),
        float3(0.17697, 0.8124, 0.01063)/float3(0.17697),
        float3(0.0,     0.01,   0.99)/float3(0.17697)]);
    static let xyz2rgbM = float3x3(rows:[
        float3(0.41847,   -0.15866,  -0.082835),
        float3(-0.091169,  0.25243,   0.015708 ),
        float3(0.0009209, -0.0025498, 0.17860)]);
    
    public func toTempTint(_ value: float3) -> float2 {
        let xyz = IMPColorSpace.rgb2xyzM * self.to(.rgb, value: value)
        let xy = IMPBridge.xyz2xy(xyz)
        return IMPBridge.xy2TempTint(xy)
    }

    public func fromTempTint(_ value: float2) -> float3 {
        let xy  = IMPBridge.tempTint2xy(value)
        let rgb = IMPColorSpace.xyz2rgbM * IMPBridge.xy2xyz(xy) 
        return from(.rgb, value: rgb)
    }
    
    private func convert(from from_cs:IMPColorSpace, to to_cs:IMPColorSpace, value:float3) -> float3 {
        return IMPBridge.convert(IMPColorSpaceIndex(rawValue: Int32(from_cs.index)),
                                 to: IMPColorSpaceIndex(rawValue: Int32(to_cs.index)),
                                 value: value)
    } 
    
    private func toNormalized(from from_cs:IMPColorSpace, to to_cs:IMPColorSpace, value:float3) -> float3 {
        return IMPBridge.toNormalized(IMPColorSpaceIndex(rawValue: Int32(from_cs.index)),
                                 to: IMPColorSpaceIndex(rawValue: Int32(to_cs.index)),
                                 value: value)
    } 
    
    private func fromNormalized(from from_cs:IMPColorSpace, to to_cs:IMPColorSpace, value:float3) -> float3 {
        return IMPBridge.fromNormalized(IMPColorSpaceIndex(rawValue: Int32(from_cs.index)),
                                      to: IMPColorSpaceIndex(rawValue: Int32(to_cs.index)),
                                      value: value)
    }
        
}
