//
//  IMPCameraFocus.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 27/02/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
import Foundation
import AVFoundation

///  Focus settings
///
///  - Auto:           Auto focus mode at POI with beginning and completition blocks
///  - ContinuousAuto: Continuous Auto focus mode with beginning and completition blocks
///  - Locked:         Locked Focus mode
///  - Reset:          Reset foucus to center POI
public enum IMPCameraFocus{
    
    case Auto          (atPoint:CGPoint, restriction:AVCaptureAutoFocusRangeRestriction?, begin:IMPCameraPointBlockType?, complete:IMPCameraPointBlockType?)
    case ContinuousAuto(atPoint:CGPoint, restriction:AVCaptureAutoFocusRangeRestriction?, begin:IMPCameraPointBlockType?, complete:IMPCameraPointBlockType?)
    case Locked(position:Float?, complete:IMPCameraPointBlockType?)
    case Reset(complete:IMPCameraPointBlockType?)
    
    /// Device focus mode
    public var mode: AVCaptureFocusMode {
        switch self {
        case .Auto(_,_,_,_): return .autoFocus
        case .ContinuousAuto(_,_,_,_): return .continuousAutoFocus
        case .Locked(_,_): return .locked
        case .Reset(_): return .continuousAutoFocus
        }
    }
    
    /// Focus range restriction
    public var restriction:AVCaptureAutoFocusRangeRestriction {
        if let r = self.realRestriction {
            return r
        }
        else {
            return .none
        }
    }
    
    var realRestriction:AVCaptureAutoFocusRangeRestriction? {
        switch self {
        case .Auto(_,let restriction,_,_): return restriction
        case .ContinuousAuto(_,let restriction,_,_): return restriction
        default:
            return .none
        }
    }
    
    // Lens desired position
    var position:Float? {
        switch self {
        case .Locked(let position,_): return position
        default:
            return nil
        }
    }
    
    // POI of focusing
    var poi: CGPoint? {
        switch self {
        case .Auto(let focusPoint,_,_,_): return focusPoint
        case .ContinuousAuto(let focusPoint,_,_,_): return focusPoint
        case .Locked(_,_): return nil
        case .Reset(_): return CGPoint(x: 0.5,y: 0.5)
        }
    }
    
    // Begining block calls when lens start to change its position
    var begin: IMPCameraPointBlockType? {
        switch self {
        case .Auto(_, _, let beginBlock, _): return beginBlock
        case .ContinuousAuto(_, _, let beginBlock, _): return beginBlock
        case .Locked(_,_): return nil
        case .Reset(_): return nil
        }
    }
    
    // Completetion block calls when focus has adjusted
    var complete: IMPCameraPointBlockType? {
        switch self {
        case .Auto(_,_,_, let completeBlock): return completeBlock
        case .ContinuousAuto(_,_,_, let completeBlock): return completeBlock
        case .Locked(_,let completeBlock): return completeBlock
        case .Reset(let completeBlock): return completeBlock
        }
    }
}
#endif
