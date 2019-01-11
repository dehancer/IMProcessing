//
//  IMPCameraExtentions.swift
//  IMPCameraManager
//
//  Created by Denis Svinarchuk on 27/02/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
    
    
    public extension AVCaptureVideoOrientation {
        
        //
        //  AVCaptureVideoOrientation
        //        case Portrait            // Indicates that video should be oriented vertically, home button on the bottom.
        //        case PortraitUpsideDown  // Indicates that video should be oriented vertically, home button on the top.
        //        case LandscapeRight      // Indicates that video should be oriented horizontally, home button on the right.
        //        case LandscapeLeft       // Indicates that video should be oriented horizontally, home button on the left.
        //
        //  UIDeviceOrientation
        //        case Unknown            -> Portrait
        //        case Portrait           -> Portrait            // Device oriented vertically, home button on the bottom
        //        case PortraitUpsideDown -> PortraitUpsideDown  // Device oriented vertically, home button on the top
        //        case LandscapeLeft      -> LandscapeRight      // Device oriented horizontally, home button on the right !!!
        //        case LandscapeRight     -> LandscapeLeft       // Device oriented horizontally, home button on the left !!!
        //        case FaceUp             -> Portrait            // Device oriented flat, face up
        //        case FaceDown           -> Portrait            // Device oriented flat, face down
        
        
        init?(deviceOrientation:UIDeviceOrientation) {
            switch deviceOrientation {
            case .portraitUpsideDown:
                self.init(rawValue: AVCaptureVideoOrientation.portraitUpsideDown.rawValue)
            case .landscapeLeft:
                self.init(rawValue: AVCaptureVideoOrientation.landscapeRight.rawValue)
            case .landscapeRight:
                self.init(rawValue: AVCaptureVideoOrientation.landscapeLeft.rawValue)
            default:
                self.init(rawValue: AVCaptureVideoOrientation.portrait.rawValue)
            }
        }
    }

#else
    import Cocoa
#endif
import AVFoundation


#if os(iOS)

public typealias IMPCameraPointBlockType = ((_ camera:IMPCameraManager, _ point:CGPoint)->Void)

///  @brief Still image compression settings
public struct IMPCameraCompression {
    public let isHardware:Bool
    public let quality:Float
    public init() {
        isHardware = true
        quality = 1
    }
    public init(isHardware:Bool, quality:Float){
        self.isHardware = isHardware
        self.quality = quality
    }
}

public extension CMTime {
    
    /// Get exposure duration
    public var duration:(value:Int, scale:Int) {
        return (Int(self.value),Int(self.timescale))
    }
    
    /// Create new exposure duration
    public init(duration: (value:Int, scale:Int)){
        self = CMTimeMake(Int64(duration.value), Int32(duration.scale))
    }
}

#endif
