//
//  IMPCameraManager.swift
//  IMProcessing
//
//  Created by denis svinarchuk on 04.03.16.
//  Copyright © 2016 Dehancer.photo. All rights reserved.
//

#if os(iOS)
    
    import UIKit
    import AVFoundation
    import CoreImage
    import CoreMedia
    import CoreMedia.CMBufferQueue
    

    /// Camera manager
    @available(iOS 10.2, *)
    public class IMPCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
        
        public typealias PointBlockType = IMPCameraPointBlockType
        
        public typealias Focus = IMPCameraFocus
        public typealias Exposure = IMPCameraExposure
        
        public typealias CameraCompleteBlockType    = ((_ camera:IMPCameraManager)->Void)
        public typealias CameraEventBlockType       = ((_ camera:IMPCameraManager, _ ready:Bool)->Void)
        public typealias VideoEventBlockType        = ((_ camera:IMPCameraManager, _ running:Bool)->Void)
        public typealias ZomingCompleteBlockType    = ((_ camera:IMPCameraManager, _ factor:Float)->Void)

        public typealias VideoBufferCompleteBlockType = ((_ camera:IMPCameraManager, _ buffer:CVImageBuffer)->Void)
        public typealias CapturingCompleteBlockType = ((_ camera:IMPCameraManager, _ finished:Bool, _ file:String?, _ metadata:NSDictionary?, _ error:NSError?)->Void)
        
        
        //
        // Public API
        //
        
            
        /// Test camera session state
        public var isReady:Bool {
            return session.isRunning
        }
        
        public var deviceOrientation:UIDeviceOrientation{
            return _deviceOrientation
        }
        
        public var previewEnabled = true {
            didSet{
                clearPreviewLayer?.isHidden = !previewEnabled
            }
        }
        
        var containerView:UIView!
        var rotationHandler:IMPMotionManager.RotationHandler!
        
        ///
        ///  Create Camera Manager instance
        ///
        ///  - parameter containerView: container view contains live view window
        ///
        public init(containerView:UIView) {
            
            super.init()
            
            rotationHandler = IMPMotionManager.sharedInstance.addRotationObserver(observer: { (orientation) in
                self._deviceOrientation = orientation
            })
            
            self.containerView = containerView
            
            defer{
                
                _currentCamera = cameraSession.defaultCamera(type: .builtInWideAngleCamera, position: .back)

                session.set(currentCamera: _currentCamera)
                
                self.clearPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                self.clearPreviewLayer.isHidden = true
                self.clearPreviewLayer.frame = self.containerView.bounds
                self.clearPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.containerView.layer.addSublayer(self.clearPreviewLayer)
                
                NotificationCenter.default.addObserver(self, selector: #selector(runningNotification(event:)),
                                                       name: .AVCaptureSessionDidStartRunning,
                                                       object: self.session)
                NotificationCenter.default.addObserver(self, selector: #selector(runningNotification(event:)),
                                                       name: .AVCaptureSessionDidStopRunning,
                                                       object: self.session)

            }
        }
        
        ///  Check access to camera
        ///
        ///  - parameter complete: complete hanlder
        ///
        public func requestAccess(complete:@escaping ((Bool) -> Void)) {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {
                (granted: Bool) -> Void in
                complete(granted)
            });
        }

        
        ///
        ///  Start camera manager capturing video frames
        ///
        ///  - parameter access: access handler
        ///
        public func start(access:((Bool) -> Void)?=nil) {
            requestAccess(complete: { (granted) -> Void in
                if granted {
                    
                    //
                    // start...
                    //
                    
                    if !self.session.isRunning {
                        self.session.queue.async {
                            self.session.startRunning()
                        }
                    }
                }
                if let a = access {
                    a(granted)
                }
            })
        }
        
        
        ///  Stop camera manager capturing video frames
        public func stop(complete:((Void)->Void)? = nil) {
            if session.isRunning {
                self.session.queue.async {
                    self.session.stopRunning()
                    self.isVideoStarted = false
                    complete?()
                }
            }
        }
        
        ///  Pause video frames capturing and present in liveView
        public func pause() {
            isVideoPaused = true
            self.videoObserversHandle()
        }
        
        ///  Resume paused presentation of video frames in liveView
        public func resume() {
            if !isReady{
                start()
            }
            else {
                isVideoPaused = false
            }
        }

        public var availableCameras:[AVCaptureDevice] {
            return cameraSession.devices
        }
        
        lazy var _deviceOrientation:UIDeviceOrientation = .unknown
        
        @available(iOS 10.2, *)
        lazy var cameraSession:IMPCameraSession = IMPCameraSession()
        
        lazy var session:IMPAVSession = IMPAVSession(sampleBufferDelegate: self)
        
        public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
            
            if isVideoPaused {
                return
            }

            if !isVideoStarted || isVideoSuspended{
                isVideoStarted = true
                isVideoSuspended = false
                videoObserversHandle()
            }

            if !clearPreviewLayer.isHidden {
                return
            }

            guard session.frameSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success else { return }

            if let previewBuffer = previewBufferQueue {

                // This is a shallow queue, so if image
                // processing is taking too long, we'll drop this frame for preview (this
                // keeps preview latency low).
                
                let err = CMBufferQueueEnqueue(previewBuffer, sampleBuffer)
                
                if err == 0 {
                    session.queue.async(group: nil, qos: .background, flags: .noQoS) { [unowned self] in
                        if let  sbuf = CMBufferQueueGetHead(previewBuffer) {
                            if let pixelBuffer = CMSampleBufferGetImageBuffer(sbuf as! CMSampleBuffer) {
                                self.videoBufferObserversHandle(buffer: pixelBuffer)
                            }
                        }
                        CMBufferQueueReset(self.previewBufferQueue!)
                    }
                }
            }
            else if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
                session.queue.async(group: nil, qos: .background, flags: .noQoS) { [unowned self] in
                    self.videoBufferObserversHandle(buffer: pixelBuffer)
                }
                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            }
            
            session.frameSemaphore.signal()
        }

        var clearPreviewLayer:AVCaptureVideoPreviewLayer!

        
//        ///  Toggling between cameras
//        ///
//        ///  - parameter complete: complete operations after togglinig
//        public func toggleCamera(complete:((_ camera:IMPCameraManager, _ toggled:Bool)->Void)?=nil) {
//            dispatch_async(sessionQueue){
//                let position = self.cameraPosition
//                self.rotateCamera()                
//                if let complete = complete {
//                    complete(camera: self, toggled: position == self.cameraPosition)
//                }
//            }
//        }
//        
//        /// Make compression of still images with hardware compression layer instead of turbojpeg lib
//        public var compression = IMPCameraManager.Compression(isHardware: true, quality: 1){
//            didSet{
//                updateStillImageSettings()
//            }
//        }
//        
//        /// Get front camera capture device reference
//        public var frontCamera:AVCaptureDevice? {
//            return _frontCamera
//        }
//        lazy var _frontCamera = IMPCameraManager.camera(position: .front)
//        
//        /// Get back camera caprure reference
//        public var backCamera:AVCaptureDevice? {
//            return _backCamera
//        }
//        lazy var _backCamera  = IMPCameraManager.camera(position: .back)
//        
//        lazy var currentFocus:Focus = {
//            switch self.currentCamera.focusMode {
//            case .locked:
//                return .Locked(position: nil, complete: nil)
//            case .autoFocus:
//                return .Auto(atPoint: CGPoint(x: 0.5,y: 0.5), restriction: nil, begin: nil,complete: nil)
//            case .continuousAutoFocus:
//                return .ContinuousAuto(atPoint: CGPoint(x: 0.5,y: 0.5), restriction: nil, begin: nil,complete: nil)
//            }
//        }()
//        
//        /// Get/Set current focus settings
//        public var focus:Focus {
//            set {
//                currentFocus = newValue
//                controlCameraFocus(atPoint: currentFocus.poi,
//                                   action: { (poi) in
//                                    
//                                    if newValue.mode != .locked {
//                                        self.currentCamera.focusPointOfInterest = poi
//                                    }
//                                    
//                                    if let position = newValue.position {
//                                        if self.currentCamera.isFocusModeSupported(.locked) {
//                                            self.currentCamera.setFocusModeLockedWithLensPosition(position, completionHandler: { (time) in
//                                                if let complete = self.currentFocus.complete {
//                                                    complete(self, self.focusPOI)
//                                                }
//                                            })
//                                        }
//                                    }
//                                    else {
//                                        if self.currentCamera.isAutoFocusRangeRestrictionSupported {
//                                            if let r = self.currentFocus.realRestriction {
//                                                self.currentCamera.autoFocusRangeRestriction = r
//                                            }
//                                        }
//                                        self.currentCamera.focusMode = self.currentFocus.mode
//                                    }
//                                    
//                    }, complete: nil)
//            }
//            get {
//                return currentFocus
//            }
//        }
//        
//        /// Get the camera focus point of interest (POI)
//        public var focusPOI:CGPoint {
//            return currentCamera.focusPointOfInterest
//        }
//
//        
//        lazy var currentExposure:Exposure = {
//            switch self.currentCamera.exposureMode {
//            case .locked:
//                return .Locked(complete: nil)
//            case .autoExpose:
//                return .Auto(atPoint: CGPoint(x: 0.5,y: 0.5),begin: nil,complete: nil)
//            case .continuousAutoExposure:
//                return .ContinuousAuto(atPoint: CGPoint(x: 0.5,y: 0.5),begin: nil,complete: nil)
//            default:
//                return .Locked(complete: nil)
//            }
//        }()
//        
//
//        /// Get/Set current exposure settings
//        public var exposure:Exposure {
//            set {
//                currentExposure = newValue
//                
//                controlCameraFocus(atPoint: currentExposure.poi,
//                                   action: { (poi) in
//                                    if newValue.mode == .custom{
//                                        
//                                        if let begin = newValue.begin {
//                                            begin(self, self.exposurePOI)
//                                        }
//                                        
//                                        var duration = newValue.duration
//                                        
//                                        if AVCaptureExposureDurationCurrent != duration {
//                                            if newValue.duration<self.exposureDurationRange.min{
//                                                duration = self.exposureDurationRange.min
//                                            }
//                                            else if newValue.duration>self.exposureDurationRange.max{
//                                                duration = self.exposureDurationRange.max
//                                            }
//                                        }
//                                        
//                                        var iso = newValue.iso
//                                        
//                                        if AVCaptureISOCurrent != iso {
//                                            if iso < self.exposureISORange.min {
//                                                iso = self.exposureISORange.min
//                                            }
//                                            else if iso > self.exposureISORange.max {
//                                                iso = self.exposureISORange.max
//                                            }
//                                        }
//                                        
//                                        self.currentCamera.setExposureModeCustomWithDuration(
//                                            duration,
//                                            iso: iso,
//                                            completionHandler: { (time) in
//                                                if let complete = newValue.complete {
//                                                    complete(self, self.exposurePOI)
//                                                }
//                                            }
//                                        )
//
//                                    }
//                                    else{
//                                        
//                                        self.currentCamera.exposureMode = newValue.mode
//                                        
//                                        if newValue.mode != .locked {
//                                            self.currentCamera.exposurePointOfInterest = poi
//                                        }
//                                        
//                                        if newValue.mode == .locked {
//                                            if let complete = newValue.complete {
//                                                complete(self, self.exposurePOI)
//                                            }
//                                        }
//                                        
//                                    }
//                    }, complete: nil)
//            }
//            get {
//                return currentExposure
//            }
//        }
//        
//        /// Get the camera exposure point of interest (POI)
//        public var exposurePOI:CGPoint {
//            return currentCamera.exposurePointOfInterest
//        }
//
//        /// Get the camera exposure duration range limit
//        public lazy var exposureDurationRange:(min:CMTime,max:CMTime) = {
//            return (self.currentCamera.activeFormat.minExposureDuration,self.currentCamera.activeFormat.maxExposureDuration)
//        }()
//
//        /// Get curent exposure duration
//        public var exposureDuration:CMTime{
//            return self.currentCamera.exposureDuration
//        }
//
//        /// Get the camera ISO range limit
//        public lazy var exposureISORange:(min:Float,max:Float) = {
//            return (self.currentCamera.activeFormat.minISO, self.currentCamera.activeFormat.maxISO)
//        }()
//        
//        /// Get current ISO speed value
//        public var exposureISO:Float{
//            return self.currentCamera.iso
//        }
//        
//        /// Get current lens position
//        public var lensPosition:Float {
//            return self.currentCamera.lensPosition
//        }
//        
//        /// Set focusing smooth mode
//        public var smoothFocusEnabled:Bool {
//            set {
//                controlCamera(supported: currentCamera.isSmoothAutoFocusSupported, action: { (poi) in
//                    self.currentCamera.isSmoothAutoFocusEnabled = newValue
//                })
//            }
//            get {
//                return currentCamera.isSmoothAutoFocusSupported && currentCamera.isSmoothAutoFocusEnabled
//            }
//        }
//        
//        /// Get exposure compensation range in f-stops
//        public lazy var exposureCompensationRange:(min:Float,max:Float) = {
//            return (self.currentCamera.minExposureTargetBias,self.currentCamera.maxExposureTargetBias)
//        }()
//        
//        /// Set exposure compensation in f-stops
//        public var exposureCompensation:Float {
//            set{
//                if self.currentCamera == nil {
//                    return
//                }
//                do {
//                    
//                    try self.currentCamera.lockForConfiguration()
//                    self.currentCamera.setExposureTargetBias(newValue, completionHandler:nil)
//                    self.currentCamera.unlockForConfiguration()
//                    
//                }
//                catch let error as NSError {
//                    NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                }
//            }
//            
//            get {
//                return currentCamera.exposureTargetBias
//            }
//        }
//        
        ///  Add new observer calls when camera device change session state on ready to capture and vice versa.
        ///
        ///  - parameter observer: camera event block
        public func add(cameraObserver:@escaping CameraEventBlockType){
            cameraEventHandlers.append(cameraObserver)
        }
        
        ///  Add new observer calls when video capturing change video streaming state.
        ///
        ///  - parameter observer: camera event block
        public func add(videoObserver:@escaping VideoEventBlockType){
            videoEventHandlers.append(videoObserver)
        }

        ///  Add new observer calls when video stream get a new buffer.
        ///
        ///  - parameter observer: camera event block
        public func add(streamObserver:@escaping VideoBufferCompleteBlockType){
            videoBufferHandlers.append(streamObserver)
        }
        
//
//        ///  Add new observer calls when the first frame from video stream presents in live viewport after camera starting.
//        ///
//        ///  - parameter observer: camera event block
//        public func addLiveViewReadyObserver(observer:@escaping LiveViewEventBlockType){
//            liveViewReadyHandlers.append(observer)
//        }
//        
//        /// Test camera torch
//        public var hasTorch:Bool {
//            return currentCamera.hasTorch
//        }
//
//        /// Change torch mode. It can be .Off, .On, .Auto
//        public var torchMode:AVCaptureTorchMode {
//            set{
//                if hasFlash && newValue != currentCamera.torchMode &&
//                    currentCamera.isTorchModeSupported(newValue)
//                {
//                    do{
//                        try currentCamera.lockForConfiguration()
//                        currentCamera.torchMode = newValue
//                        currentCamera.unlockForConfiguration()
//                    }
//                    catch let error as NSError {
//                        NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                    }
//                }
//            }
//            get{
//                return currentCamera.torchMode
//            }
//        }
//
//        /// Test camera flash
//        public var hasFlash:Bool {
//            return currentCamera.hasFlash
//        }
//        
//        /// Change flash mode. It can be .Off, .On, .Auto
//        public var flashMode:AVCaptureFlashMode {
//            set{
//                if hasFlash && newValue != currentCamera.flashMode &&
//                currentCamera.isFlashModeSupported(newValue)
//                {
//                    do{
//                        try currentCamera.lockForConfiguration()
//                        currentCamera.flashMode = newValue
//                        currentCamera.unlockForConfiguration()
//                    }
//                    catch let error as NSError {
//                        NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                    }
//                }
//            }
//            get{
//                return currentCamera.flashMode
//            }
//        }
//        
//        /// Get maximum video zoom factor presentation
//        public lazy var maximumZoomFactor:Float = {
//            return self.currentCamera.activeFormat.videoMaxZoomFactor.float
//        }()
//        
//        /// Get maximum video zoom factor presentation
//        public var zoomFactor:Float {
//            get {
//                return currentCamera.videoZoomFactor.float
//            }
//            set {
//                setZoom(factor: newValue, animate: false, complete: nil)
//            }
//        }
//        
//        
//        ///  Set current zoom presentation of video
//        ///
//        ///  - parameter factor:   zoom factor
//        ///  - parameter animate:  animate or not zomming proccess before presentation
//        ///  - parameter complete: complete block
//        public func setZoom(factor:Float, animate:Bool=true, complete:ZomingCompleteBlockType?=nil) {
//            if factor >= 1.0 && factor <= maximumZoomFactor {
//                dispatch_async(sessionQueue){
//                    do{
//                        try self.currentCamera.lockForConfiguration()
//                        
//                        self.zomingCompleteQueue.append(CompleteZomingFunction(complete: complete, factor: factor))
//                        
//                        if animate {
//                            self.currentCamera.rampToVideoZoomFactor(factor.cgfloat, withRate: 30)
//                        }
//                        else{
//                            self.currentCamera.videoZoomFactor = factor.cgfloat
//                        }
//                        self.currentCamera.unlockForConfiguration()
//                    }
//                    catch let error as NSError {
//                        NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                    }
//                }
//            }
//        }
//        
//        /// Cancel zooming
//        public func cancelZoom(){
//            dispatch_async(sessionQueue){
//                do{
//                    try self.currentCamera.lockForConfiguration()
//                    self.currentCamera.cancelVideoZoomRamp()
//                    self.currentCamera.unlockForConfiguration()
//                }
//                catch let error as NSError {
//                    NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                }
//            }
//        }
//        

        deinit{
            IMPMotionManager.sharedInstance.removeRotationObserver(observer: rotationHandler)
            removeCameraObservers()
        }
        
        public var frameRate:Int {
            get {
                return currentFrameRate
            }
            set {
                resetFrameRate(frameRate: newValue)
            }
        }
        
        var  currentFrameRate:Int = 60
        
        func resetFrameRate(frameRate:Int){
            
            currentFrameRate = frameRate
            
            let activeCaptureFormat = self.currentCamera.activeFormat
            
            for rate in activeCaptureFormat?.videoSupportedFrameRateRanges as! [AVFrameRateRange] {
                if( frameRate >= rate.minFrameRate.int && frameRate <= rate.maxFrameRate.int ) {
                    do{
                        try currentCamera.lockForConfiguration()
                        
                        currentCamera.activeVideoMinFrameDuration = CMTimeMake(1, Int32(frameRate))
                        currentCamera.activeVideoMaxFrameDuration = CMTimeMake(1, Int32(frameRate))
                        
                        currentCamera.unlockForConfiguration()
                    }
                    catch let error as NSError {
                        NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
                    }
                }
            }
        }

        
        //
        // Internal utils and vars
        //
        
        // Get current camera
        var currentCamera:AVCaptureDevice!{
            return _currentCamera
        }

        var _currentCamera:AVCaptureDevice! {
            willSet{
                if (_currentCamera != nil) {
                    removeCameraObservers()
                }
            }
            didSet{
                addCameraObservers()
                resetFrameRate(frameRate: currentFrameRate)
            }
        }

        var isVideoStarted   = false
        
        var isVideoPaused    = false {
            didSet {
                isVideoSuspended = oldValue
            }
        }
        var isVideoSuspended      = false

        var cameraEventHandlers = [CameraEventBlockType]()
        var videoEventHandlers  = [VideoEventBlockType]()
        var videoBufferHandlers  = [VideoBufferCompleteBlockType]()

        func cameraObserversHandle() {
            for o in cameraEventHandlers {
                o(self, isReady)
            }
        }
        
        func videoObserversHandle() {
            for o in videoEventHandlers {
                o(self, session.isRunning)
            }
        }

        func videoBufferObserversHandle(buffer:CVImageBuffer) {
            for o in videoBufferHandlers {
                o(self, buffer)
            }
        }

        
//
//        func controlCameraFocus(atPoint point:CGPoint?, action:((_ poi:CGPoint)->Void), complete:CameraCompleteBlockType?=nil) {
//            controlCamera(atPoint: point,
//                          supported: self.currentCamera.isFocusPointOfInterestSupported
//                            && self.currentCamera.isFocusModeSupported(.autoFocus),
//                          action: action,
//                          complete: complete)
//        }
//
//        func controlCameraExposure(atPoint point:CGPoint?, action:((_ poi:CGPoint)->Void), complete:CameraCompleteBlockType?=nil) {
//            controlCamera(atPoint: point,
//                          supported: self.currentCamera.isExposurePointOfInterestSupported
//                            && self.currentCamera.isExposureModeSupported(.autoExpose),
//                          action: action,
//                          complete: complete)
//        }
//
//        func controlCamera(atPoint point:CGPoint?=nil, supported: Bool, action:((_ poi:CGPoint)->Void), complete:CameraCompleteBlockType?=nil) {
//            
//            if self.currentCamera == nil {
//                return
//            }
//            
//            if supported
//            {
//                dispatch_async(sessionQueue){
//                    
//                    let poi = point == nil ? CGPoint(x:0.5,y: 0.5) : self.pointOfInterestForLocation(point!)
//                    
//                    do {
//                        try self.currentCamera.lockForConfiguration()
//                        
//                        action(poi: poi)
//                        
//                        self.currentCamera.unlockForConfiguration()
//                        
//                        if let complete = complete {
//                            complete(camera:self)
//                        }
//                    }
//                    catch let error as NSError {
//                        NSLog("IMPCameraManager error: \(error): \(#file):\(#line)")
//                    }
//                }
//            }
//        }
//
//        
//        //
//        // Observe camera properties...
//        //
//        
//        class CompleteZomingFunction {
//            var block:ZomingCompleteBlockType? = nil
//            var factor:Float = 0
//            init(complete:ZomingCompleteBlockType?, factor:Float){
//                self.block = complete
//                self.factor = factor
//            }
//        }
//        
//        var zomingCompleteQueue = [CompleteZomingFunction]()
//

        func addCameraObservers() {
            self.currentCamera.addObserver(self, forKeyPath: "videoZoomFactor", options: [.new,.old], context: nil)
            self.currentCamera.addObserver(self, forKeyPath: "adjustingFocus", options: [.new,.old], context: nil)
            self.currentCamera.addObserver(self, forKeyPath: "adjustingExposure", options: [.new,.old], context: nil)
            self.currentCamera.addObserver(self, forKeyPath: "exposureMode", options: [.new,.old], context: nil)
        }
        
        func removeCameraObservers() {
            self.currentCamera.removeObserver(self, forKeyPath: "videoZoomFactor", context: nil)
            self.currentCamera.removeObserver(self, forKeyPath: "adjustingFocus", context: nil)
            self.currentCamera.removeObserver(self, forKeyPath: "adjustingExposure", context: nil)
            self.currentCamera.removeObserver(self, forKeyPath: "exposureMode", context: nil)
        }
        
        public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            //print("change = \(change?[.oldKey])")
            //print("change = \(change?[.newKey])")
            
        }
        
//
//        override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
//            
//                if keyPath == "adjustingFocus"{
//                    if let new = change?[NSKeyValueChangeNewKey] as? Int {
//                        if new == 1 {
//                            if let begin = self.currentFocus.begin{
//                                begin(camera: self, point: self.focusPOI)
//                            }
//                        }
//                        else if new == 0 {
//                            if self.currentFocus.position == nil {
//                                //
//                                // .Locked at lens position is ignored
//                                //
//                                if let complete = self.currentFocus.complete{
//                                    complete(camera: self, point: self.focusPOI)
//                                    switch self.currentFocus {
//                                    case .Reset(_): self.currentFocus = .Reset(complete: nil)
//                                    default: break
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                    
//                else if keyPath == "exposureMode"{
//                    let newMod = currentCamera.exposureMode
//                    if let oldValue = change?[NSKeyValueChangeOldKey] as? Int {
//                        if let oldMode = AVCaptureExposureMode(rawValue: oldValue) {
//                            if newMod != oldMode && oldMode == .Custom {
//                                
//                                /*
//                                 It’s important to understand the relationship between exposureDuration and the minimum frame rate as represented by activeVideoMaxFrameDuration.
//                                 In manual mode, if exposureDuration is set to a value that's greater than activeVideoMaxFrameDuration, then activeVideoMaxFrameDuration will
//                                 increase to match it, thus lowering the minimum frame rate. If exposureMode is then changed to automatic mode, the minimum frame rate will
//                                 remain lower than its default. If this is not the desired behavior, the min and max frameRates can be reset to their default values for the
//                                 current activeFormat by setting activeVideoMaxFrameDuration and activeVideoMinFrameDuration to kCMTimeInvalid.
//                                 */
//                                
//                                try! currentCamera.lockForConfiguration()
//                                currentCamera.activeVideoMaxFrameDuration = kCMTimeInvalid
//                                currentCamera.activeVideoMinFrameDuration = kCMTimeInvalid
//                                currentCamera.unlockForConfiguration()
//                            }
//                        }
//                        
//                    }
//                }
//                    
//                else if keyPath == "adjustingExposure"{
//                    
//                    if self.currentExposure.mode == .Custom {
//                        return
//                    }
//                    
//                    if let new = change?[NSKeyValueChangeNewKey] as? Int {
//                        if new == 1 {
//                            if let begin = self.currentExposure.begin{
//                                begin(camera: self, point: self.exposurePOI)
//                            }
//                        }
//                        else if new == 0 {
//                            if let complete = self.currentExposure.complete{
//                                complete(camera: self, point: self.exposurePOI)
//                                switch self.currentExposure {
//                                case .Reset(_): self.currentExposure = .Reset(complete: nil)
//                                default: break
//                                }
//                            }
//                        }
//                    }
//                }
//                    
//                else if keyPath == "videoZoomFactor" {
//                    if let new = change?[NSKeyValueChangeNewKey] as? Float {
//                        if let complete = self.zomingCompleteQueue.last {
//                            if let block = complete.block {
//                                if complete.factor == new {
//                                    self.zomingCompleteQueue.removeAll()
//                                    block(camera: self, factor: complete.factor)
//                                }
//                            }
//                        }
//                    }
//                }
//        }
//        
//        func updateStillImageSettings() {
//            if compression.isHardware {
//                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG, AVVideoQualityKey: compression.quality]
//            }
//            else {
//                stillImageOutput.outputSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
//            }
//        }
//        

        func runningNotification(event:NSNotification) {
            for  o in cameraEventHandlers {
                o(self, isReady)
            }
        }

//
//        var sessionQueue = dispatch_queue_create(IMProcessing.names.prefix+"preview.video", DISPATCH_QUEUE_SERIAL)
//        
//        func updateConnection()  {
//            //
//            // Current capture connection
//            //
//            currentConnection = liveViewOutput.connection(withMediaType: AVMediaTypeVideo)
//            
//            currentConnection.automaticallyAdjustsVideoMirroring = false
//            
//            if (currentConnection.isVideoOrientationSupported){
//                currentConnection.videoOrientation = AVCaptureVideoOrientation.portrait
//            }
//            
//            if (currentConnection.isVideoMirroringSupported) {
//                currentConnection.isVideoMirrored = currentCamera == frontCamera
//            }
//            
//        }
//        
//        func initSession() {
//            if session == nil {
//                session = AVCaptureSession()
//                
//                if let s = session{
//                    dispatch_async(sessionQueue) {
//                        do {
//                            s.beginConfiguration()
//                            
//                            s.sessionPreset = AVCaptureSessionPresetPhoto
//                            
//                            //
//                            // Input
//                            //
//                            self.videoInput = try self.videoInput ?? AVCaptureDeviceInput(device: self.currentCamera)
//                            
//                            if s.canAddInput(self.videoInput) {
//                                s.addInput(self.videoInput)
//                            }
//                            
//                            //
//                            // Video Output
//                            //
//                            self.liveViewOutput = AVCaptureVideoDataOutput()
//                            self.liveViewOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
//                            self.liveViewOutput.alwaysDiscardsLateVideoFrames = true
//                            self.liveViewOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
//                            
//                            if s.canAddOutput(self.liveViewOutput) {
//                                s.addOutput(self.liveViewOutput)
//                            }
//                            
//                            //
//                            // Full size Image
//                            //
//                            self.stillImageOutput = AVCaptureStillImageOutput()
//                            
//                            if s.canAddOutput(self.stillImageOutput) {
//                                s.addOutput(self.stillImageOutput)
//                            }
//                            
//                            s.canSetSessionPreset(AVCaptureSessionPresetPhoto)
//                            
//                            s.commitConfiguration()
//                            
//                            self.updateStillImageSettings()
//                            
//                            self.updateConnection()
//                            
//                            self.clearPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
//                            self.clearPreviewLayer?.hidden = true
//                            self.clearPreviewLayer?.frame = self.containerView.bounds
//                            self.clearPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
//                            self.containerView.layer.addSublayer(self.clearPreviewLayer!)
//                            
//                            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.runningNotification(_:)), name: AVCaptureSessionDidStartRunningNotification, object: self.session)
//                            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.runningNotification(_:)), name:
//                                AVCaptureSessionDidStopRunningNotification, object: self.session)
//                        }
//                        catch let error as NSError {
//                            NSLog("IMPCameraManager error: \(error) \(#file):\(#line)")
//                        }
//                    }
//                }
//            }
//        }
//        


//
//        lazy var hasFrontCamera:Bool = {
//            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
//            for d in devices{
//                if d.position == .Front {
//                    return true
//                }
//            }
//            return false
//        }()
//        
//        func changeCamera(camera:AVCaptureDevice?) {
//            dispatch_async(sessionQueue) {
//                do {
//                    self.session.beginConfiguration()
//                    
//                    self.session.removeInput(self.videoInput)
//                    
//                    self._currentCamera = camera
//                    
//                    self.videoInput = try AVCaptureDeviceInput(device: self.currentCamera)
//                    
//                    if self.session.canAddInput(self.videoInput) {
//                        self.session.addInput(self.videoInput)
//                    }
//                    
//                    self.session.commitConfiguration()
//                    
//                    self.updateConnection()
//                }
//                catch let error as NSError {
//                    NSLog("IMPCameraManager error: \(error) \(#file):\(#line)")
//                }
//            }
//        }
//        
//        func rotateCamera() {
//            if !hasFrontCamera {
//                return
//            }
//
//            if (self.currentCamera == self.backCamera) {
//                changeCamera(camera: self.frontCamera)
//            }
//            else{
//                changeCamera(camera: self.backCamera)
//            }
//        }
//        
//        var capturingPhotoInProgress = false
//        var session:AVCaptureSession!
//        var videoInput:AVCaptureDeviceInput!
//        
//        lazy var cameraPosition:AVCaptureDevicePosition = {
//            return self.videoInput.device.position
//        }()
//        
//        var liveViewOutput:AVCaptureVideoDataOutput!
//        var stillImageOutput:AVCaptureStillImageOutput!
//        var currentConnection:AVCaptureConnection!
//        
//        static func camera(position:AVCaptureDevicePosition) -> AVCaptureDevice? {
//            
//            guard let device = AVCaptureDevice.devices().filter({ $0.position == position })                
//                .first as? AVCaptureDevice else {
//                    return nil
//            }
//            
//            do {
//                try device.lockForConfiguration()
//                if device.isWhiteBalanceModeSupported(.ContinuousAutoWhiteBalance) {
//                    device.whiteBalanceMode = .ContinuousAutoWhiteBalance
//                }
//                if device.isExposureModeSupported(.ContinuousAutoExposure){
//                    device.exposureMode = .ContinuousAutoExposure
//                }
//                device.unlockForConfiguration()
//            }
//            catch  {
//                return nil
//            }
//            
//            return device
//        }
//        
//        func pointOfInterestForLocation(location:CGPoint) -> CGPoint {
//            
//            if abs(location.x).float < 1.0 && abs(location.y).float < 1.0 {
//                return location
//            }
//            
//            let  frameSize = self.liveView.bounds.size
//            var  newLocaltion = location
//            
//            if self.cameraPosition == .front {
//                newLocaltion.x = frameSize.width - location.x
//            }
//            
//            return CGPointMake(newLocaltion.y / frameSize.height, 1 - (newLocaltion.x / frameSize.width));
//        }
//
//        static func connection(mediaType:String, connections:NSArray) -> AVCaptureConnection? {
//            
//            var videoConnection:AVCaptureConnection? = nil
//            
//            for connection in connections  {
//                for port in connection.inputPorts {
//                    if  port.mediaType.isEqual(mediaType) {
//                        videoConnection = connection as? AVCaptureConnection
//                        break;
//                    }
//                }
//                if videoConnection != nil {
//                    break;
//                }
//            }
//            
//            return videoConnection;
//        }
//        
//
        lazy var previewBufferQueue:CMBufferQueue? = {
            var queue : CMBufferQueue?
            var err : OSStatus = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &queue)
            if err != 0 || queue == nil
            {
                //let error = NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
                return nil
            }
            else
            {
                return queue
            }
        }()

        //
//        /// Frame scale factor
//        public var scaleFactor:Float = 1
//
    }
    
    
    
//
//    // MARK: - Capturing API
//    public extension IMPCameraManager {
//        //
//        // Capturing video frames and update live-view to apply IMP-filter.
//        //
//        public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {            
//            
//            if capturingPhotoInProgress {
//                return
//            }
//            
//            if isVideoPaused {
//                return
//            }
//                        
//            if connection == currentConnection {
//                
//                if !isVideoStarted || isVideoSuspended{
//                    isVideoStarted = true
//                    isVideoSuspended = false
//                    videoObserversHandle()
//                }
//                
//                if let isClearPreviewHidden = clearPreviewLayer?.hidden {
//                    if !isClearPreviewHidden {
//                        return
//                    }
//                }
//                
//                if let previewBuffer = previewBufferQueue {
//                    
//                    // This is a shallow queue, so if image
//                    // processing is taking too long, we'll drop this frame for preview (this
//                    // keeps preview latency low).
//                    
//                    let err = CMBufferQueueEnqueue(previewBuffer, sampleBuffer)
//                    
//                    if err == 0 {
//                        dispatch_async(DispatchQueue.main, {
//                            if let  sbuf = CMBufferQueueGetHead(previewBuffer) {
//                                if let pixelBuffer = CMSampleBufferGetImageBuffer(sbuf as! CMSampleBuffer) {
//                                    self.updateProvider(pixelBuffer)
//                                }
//                            }
//                            CMBufferQueueReset(self.previewBufferQueue!)
//                        })
//                    }
//                    
//                }
//                else if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//                    updateProvider(pixelBuffer)
//                }
//            }
//        }
//
//
//        ///  Capture image to file
//        ///
//        ///  - parameter file:     file path. Path can be nil, in this case photo captures to Camera Roll
//        ///  - parameter complete: completition block
//        public func capturePhoto(file:String?=nil, complete:capturingCompleteBlockType?=nil){
//            
//            if !isReady{
//                complete?(camera: self, finished: false, file: file, metadata: nil, error: nil)
//                return
//            }
//            if stillImageOutput.capturingStillImage {
//                complete?(camera: self, finished: false, file: file, metadata: nil, error: nil)
//                return
//            }
//            
//            if let complete = complete {
//                
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//                    
//                    if let connection = IMPCameraManager.connection(AVMediaTypeVideo, connections: self.stillImageOutput.connections) {
//                        
//                        connection.automaticallyAdjustsVideoMirroring = false
//                        
//                        if (connection.supportsVideoOrientation){
//                            connection.videoOrientation =  AVCaptureVideoOrientation(deviceOrientation: self.deviceOrientation)!
//                        }
//                        
//                        self.capturingPhotoInProgress = true
//                        
//                        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (sampleBuffer, error) in
//                            
//                            if error != nil {
//                                self.capturingPhotoInProgress = false
//                                complete(camera: self, finished: false, file: file, metadata: nil, error: error)
//                            }
//                            else{
//                                
//                                if let sampleBuffer = sampleBuffer {
//                                    
//                                    let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
//                                    
//                                    var meta = attachments as NSDictionary?
//                                    
//                                    if let d = meta {
//                                        
//                                        let newMeta = d.mutableCopy() as! NSMutableDictionary
//                                        
//                                        newMeta[IMProcessing.meta.versionKey]           = IMProcessing.meta.version
//                                        newMeta[IMProcessing.meta.deviceOrientationKey] = self.deviceOrientation.rawValue
//                                        
//                                        newMeta[IMProcessing.meta.imageSourceExposureMode] = self.currentCamera.exposureMode.rawValue
//                                        newMeta[IMProcessing.meta.imageSourceFocusMode] = self.currentCamera.focusMode.rawValue
//                                        
//                                        meta = newMeta
//                                    }
//                                    
//                                    do {
//                                        if self.compression.isHardware {
//                                            let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
//                                            if let file = file {
//                                                try imageDataJpeg.writeToFile(file, options: .AtomicWrite)
//                                                complete(camera: self, finished: true, file: file, metadata: meta, error: nil)
//                                            }
//                                            else {
//                                                if let image = UIImage(data: imageDataJpeg) {
//                                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//                                                    complete(camera: self, finished: true, file: file, metadata: meta, error: nil)
//                                                }
//                                            }
//                                        }
//                                        else{
//                                            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//                                                if let file = file {
//                                                    try IMPJpegturbo.writePixelBuffer(pixelBuffer, toJpegFile: file, compression: self.compression.quality.cgfloat, inputColorSpace:JPEG_TURBO_BGRA)
//                                                    complete(camera: self, finished: true, file: file, metadata: meta, error: nil)
//                                                }
//                                                else {
//                                                    complete(camera: self, finished: true, file: nil, metadata: meta, error: nil)
//                                                }
//                                            }
//                                            else {
//                                                let error = NSError(domain: IMProcessing.names.prefix+"camera.roll",
//                                                    code: 0,
//                                                    userInfo: [
//                                                        NSLocalizedDescriptionKey: String(format: NSLocalizedString("Hardware saving to camer roll is only supported", comment:"")),
//                                                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Saving to Camera Roll error", comment:""))
//                                                    ])
//                                                complete(camera: self, finished: false, file: file, metadata: meta, error: error)
//                                            }
//                                        }
//                                    }
//                                    catch let error as NSError{
//                                        complete(camera: self, finished: false, file: file, metadata: meta, error: error)
//                                    }
//                                }
//                                self.capturingPhotoInProgress = false
//                            }
//                        })
//                    }
//                }
//            }
//        }
//    }
    
#endif
