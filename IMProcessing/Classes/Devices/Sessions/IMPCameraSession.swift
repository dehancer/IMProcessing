//
//  IMPCameraSession.swift
//  Pods
//
//  Created by denis svinarchuk on 18.02.17.
//
//

#if os(iOS)
import AVFoundation

@available(iOS 10.2, *)
class IMPCameraSession {
    
    private let types = [AVCaptureDeviceType.builtInWideAngleCamera, AVCaptureDeviceType.builtInDualCamera, AVCaptureDeviceType.builtInTelephotoCamera]
    
    private lazy var discovery:AVCaptureDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(
        deviceTypes: self.types,
        mediaType: AVMediaTypeVideo, position: .unspecified)
    
    var devices:[AVCaptureDevice] {
        return discovery.devices
    }
    
    func defaultCamera(type:AVCaptureDeviceType, position:AVCaptureDevicePosition) -> AVCaptureDevice? {
        for d in devices {
            if d.deviceType == type && d.position == position {
                return d
            }
        }
        
        return nil
    }
    
    func defaultCamera(id:String) -> AVCaptureDevice? {
        for d in devices {
            if d.uniqueID == id {
                return d
            }
        }
        
        return nil
    }
}
#endif
