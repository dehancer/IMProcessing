//
//  IMPCameraExposure.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 27/02/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
import Foundation
import AVFoundation

///  Exposure settings
///
///  - Custom:         Custom exposure with duration
///  - Auto:           Auto exposure mode at POI with beginning and completition blocks
///  - ContinuousAuto: Continuous Auto exposure mode with beginning and completition blocks
///  - Locked:         Locked exposure mode
///  - Reset:          Reset exposure to center POI
public enum IMPCameraExposure {
    
    case Custom(duration:CMTime,iso:Float,begin:IMPCameraPointBlockType?,complete:IMPCameraPointBlockType?)
    case Auto(atPoint:CGPoint,begin:IMPCameraPointBlockType?,complete:IMPCameraPointBlockType?)
    case ContinuousAuto(atPoint:CGPoint,begin:IMPCameraPointBlockType?,complete:IMPCameraPointBlockType?)
    case Locked(complete:IMPCameraPointBlockType?)
    case Reset(complete:IMPCameraPointBlockType?)
    
    /// Device focus mode
    public var mode: AVCaptureExposureMode {
        switch self {
        case .Custom(_,_,_,_): return .custom
        case .Auto(_,_,_): return .autoExpose
        case .ContinuousAuto(_,_,_): return .continuousAutoExposure
        case .Locked(_): return .locked
        case .Reset(_): return .continuousAutoExposure
        }
    }
    
    var duration: CMTime {
        switch self {
        case .Custom(let duration,_,_,_): return duration
        default: return AVCaptureExposureDurationCurrent
        }
    }
    
    var iso:Float{
        switch self {
        case .Custom(_,let iso,_,_): return iso
        default: return AVCaptureISOCurrent
        }
    }
    
    // POI of exposure
    var poi: CGPoint? {
        switch self {
        case .Custom(_,_,_,_): return nil
        case .Auto(let focusPoint,_,_): return focusPoint
        case .ContinuousAuto(let focusPoint,_,_): return focusPoint
        case .Locked(_): return nil
        case .Reset(_): return CGPoint(x: 0.5,y: 0.5)
        }
    }
    
    //
    var begin: IMPCameraPointBlockType? {
        switch self {
        case .Custom(_,_, let beginBlock, _): return beginBlock
        case .Auto(_, let beginBlock, _): return beginBlock
        case .ContinuousAuto(_, let beginBlock, _): return beginBlock
        case .Locked(_): return nil
        case .Reset(_): return nil
        }
    }
    
    // Completetion block calls when focus has adjusted
    var complete: IMPCameraPointBlockType? {
        switch self {
        case .Custom(_,_,_, let completeBlock): return completeBlock
        case .Auto(_,_, let completeBlock): return completeBlock
        case .ContinuousAuto(_,_, let completeBlock): return completeBlock
        case .Locked(let completeBlock): return completeBlock
        case .Reset(let completeBlock): return completeBlock
        }
    }
}
#endif
