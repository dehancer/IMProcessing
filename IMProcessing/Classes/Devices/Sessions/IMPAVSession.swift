//
//  IMPAVSession.swift
//  Pods
//
//  Created by denis svinarchuk on 18.02.17.
//
//

import Foundation
import AVFoundation

class IMPAVSession:AVCaptureSession {
    
    let frameSemaphore = DispatchSemaphore(value:1)

    let queue:DispatchQueue = DispatchQueue(label: "avsession.improcessing.com")
    var videoInput:AVCaptureDeviceInput?
    lazy var liveViewOutput:AVCaptureVideoDataOutput = {
        var o = AVCaptureVideoDataOutput()
        if let delegate = self.sampleBufferDelegate {
            o.setSampleBufferDelegate(delegate, queue: self.queue)
        }
        o.alwaysDiscardsLateVideoFrames = true
        o.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
        return o
    }()
    
    var currentConnection:AVCaptureConnection!

    
    var sampleBufferDelegate:AVCaptureVideoDataOutputSampleBufferDelegate? = nil {
        didSet{
            liveViewOutput.setSampleBufferDelegate(sampleBufferDelegate, queue: self.queue)
        }
    }
    
    override init() {
        super.init()
    }
    
    convenience init(sampleBufferDelegate:AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.init()
        self.sampleBufferDelegate = sampleBufferDelegate
    }
    
    func set(currentCamera:AVCaptureDevice) {
        queue.async {
            self.configure(currentCamera: currentCamera)
        }
    }
    
    private func configure(currentCamera:AVCaptureDevice)  {
        beginConfiguration()
        
        sessionPreset = AVCaptureSession.Preset.photo
        
        do{
            
            if findInput(input:videoInput) {
                removeInput(videoInput!)
            }            
            
            videoInput = try AVCaptureDeviceInput(device: currentCamera)
            
            if canAddInput(videoInput!) {
                addInput(videoInput!)
            }
            
            if !findOutput(output:liveViewOutput) && canAddOutput(liveViewOutput){
                addOutput(liveViewOutput)                
            }
            
            updateConnection()            
        }
        catch let error {
             NSLog("IMPCameraManager error: \(error) \(#file):\(#line)")
        }
        
        commitConfiguration()
    }
    
    func findOutput(output:AVCaptureVideoDataOutput?) -> Bool {
        for o in outputs {
            if o as! AVCaptureVideoDataOutput === output {
                return true
            }
        }
        return false
    }
    
    func findInput(input:AVCaptureDeviceInput?) -> Bool {
        for i in inputs {
            if i as! AVCaptureDeviceInput === input {
                return true
            }
        }
        return false
    }

    func updateConnection()  {
        //
        // Current capture connection
        //
        currentConnection = liveViewOutput.connection(with: AVMediaType.video)
        
        currentConnection.automaticallyAdjustsVideoMirroring = false
        
        if (currentConnection.isVideoOrientationSupported){
            currentConnection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        if (currentConnection.isVideoMirroringSupported) {
            //currentConnection.isVideoMirrored = currentCamera == frontCamera
        }
    }

}
