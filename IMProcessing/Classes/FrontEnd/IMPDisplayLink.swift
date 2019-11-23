//
//  IMPDisplayLink.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 07/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo

#if os(iOS)
    
    public class IMPDisplayLink {
        
        public  var isPaused:Bool{
            set {
                displayLink.isPaused = newValue
            }
            get {
                return displayLink.isPaused
            }
        }
        
        public var systemFramesPersecond: Int {
            return _systemFramesPersecond
        }
        
        
        public var preferredFramesPerSecond:Int {
            set{
                displayLink.preferredFramesPerSecond = newValue
            }
            get{
                return displayLink.preferredFramesPerSecond
            }
        }
        
        required public init(execute:@escaping ((CFTimeInterval)->Void)){
            handler = execute
            displayLink.add(to: .current, forMode: .commonModes)
        }

        private lazy var _systemFramesPersecond: Int = self.displayLink.preferredFramesPerSecond

        private lazy var displayLink:CADisplayLink = CADisplayLink(target_left: self, selector: #selector(procesingLinkHandler))
        
        private var handler:((CFTimeInterval)->Void)

        @objc fileprivate func procesingLinkHandler() {
            handler(displayLink.timestamp)
        }
        
        deinit {
             displayLink.invalidate()
        }
    }
    
#elseif os(OSX)
    
    //
    //
    // http://stackoverflow.com/questions/25981553/cvdisplaylink-with-swift
    //
    //
    public class IMPDisplayLink {
        
        public  var isPaused:Bool = true {
            didSet(oldValue){
                guard oldValue != isPaused else { return } 
                guard let link = displayLink else { return }
                if  isPaused {
                    if CVDisplayLinkIsRunning(link) {
                        CVDisplayLinkStop(link)
                    }
                }
                else{
                    if !CVDisplayLinkIsRunning(link) {
                        CVDisplayLinkStart(link)
                    }
                }
            }
        }
        
        deinit {
            guard let link = displayLink else { return }
            if !CVDisplayLinkIsRunning(link) {
                CVDisplayLinkStop(link)
            }
        }
        
        required public init(execute:@escaping ((CFTimeInterval)->Void)){
            addObserver(execute)
        }
             
        public init(){}

        public func addObserver(_ execute: @escaping ((CFTimeInterval)->Void)) {
            guard let link = displayLink else { return }
            context = Context(prefered: preferredFramesPerSecond, system: systemFramesPersecond, handler:execute)
            CVDisplayLinkSetOutputCallback(link, displayLinkOutputCallback, &context)        
        }
        
        //
        // does not affect ths version
        //
        public lazy var preferredFramesPerSecond: Int = self.systemFramesPersecond
        
        public var systemFramesPersecond: Int {
            return _systemFramesPersecond
        }
        
        private lazy var _systemFramesPersecond: Int = {
            guard let link = self.displayLink else { return 0 }
            let t = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(link)
            return Int(round(Double(t.timeScale)/Double(t.timeValue)))
        }()
                
        private let displayLink:CVDisplayLink? = {
            var link:CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)
            return link
        } ()
        
        private struct Context{
            
            var handler:((CFTimeInterval)->Void)
            
            var preferredFramesPerSecond:Int = 0
            var systemFramesPersecond: Int = 0
            
            var frameNumber:UInt64 = 0
            var lastTime:Double = 0
            
            init(prefered:Int=0, system:Int=0, handler:@escaping ((CFTimeInterval)->Void)){
                self.handler = handler
                preferredFramesPerSecond = prefered
                systemFramesPersecond = system
            }
        }
        private var context:Context?
        
        private let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {
            (displayLink: CVDisplayLink,
            inNow: UnsafePointer<CVTimeStamp>,
            inOutputTime: UnsafePointer<CVTimeStamp>,
            flagsIn: CVOptionFlags,
            flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            linkContext: UnsafeMutableRawPointer?) -> CVReturn in
            
            /*  It's prudent to also have a brief discussion about the CVTimeStamp.
             CVTimeStamp has five properties.  Three of the five are very useful
             for keeping track of the current time, calculating delta time, the
             frame number, and the number of frames per second.  The utility of
             each property is not terribly obvious from just reading the names
             or the descriptions in the Developer dcumentation and has been a
             mystery to many a developer.  Thankfully, CaptainRedmuff on
             StackOverflow asked a question that provided the equation that
             calculates frames per second.  From that equation, we can
             extrapolate the value of each field.
             
             @hostTime = current time in Units of the "root".  Yeah, I don't know.
             The key to this field is to understand that it is in nanoseconds
             (e.g. 1/1_000_000_000 of a second) not units.  To convert it to
             seconds divide by 1_000_000_000.  Dividing by videoRefreshPeriod
             and videoTimeScale in a calculation for frames per second yields
             the appropriate number of frames.  This works as a result of
             proportionality--dividing seconds by seconds.  Note that dividing
             by videoTimeScale to get the time in seconds does not work like it
             does for videoTime.
             
             framesPerSecond:
             (videoTime / videoRefreshPeriod) / (videoTime / videoTimeScale) = 59
             and
             (hostTime / videoRefreshPeriod) / (hostTime / videoTimeScale) = 59
             but
             hostTime * videoTimeScale ≠ seconds, but Units = seconds * (Units / seconds) = Units
             
             @rateScalar = ratio of "rate of device in CVTimeStamp/unitOfTime" to
             the "Nominal Rate".  I think the "Nominal Rate" is
             videoRefreshPeriod, but unfortunately, the documentation doesn't
             just say videoRefreshPeriod is the Nominal rate and then define
             what that means.  Regardless, because this is a ratio, and the fact
             that we know the value of one of the parts (e.g. Units/frame), we
             then know that the "rate of the device" is frame/Units (the units of
             measure need to cancel out for the ratio to be a ratio).  This
             makes sense in that rateScalar's definition tells us the rate is
             "measured by timeStamps".  Since there is a frame for every
             timeStamp, the rate of the device equals CVTimeStamp/Unit or
             frame/Unit.  Thus,
             
             rateScalar = frame/Units : Units/frame
             
             @videoTime = the time the frame was created since computer started up.
             If you turn your computer off and then turn it back on, this timer
             returns to zero.  The timer is paused when you put your computer to
             sleep.  This value is in Units not seconds.  To get the number of
             seconds this value represents, you have to apply videoTimeScale.
             
             @videoRefreshPeriod = the number of Units per frame (i.e. Units/frame)
             This is useful in calculating the frame number or frames per second.
             The documentation calls this the "nominal update period" and I am
             pretty sure that is quivalent to the aforementioned "nominal rate".
             Unfortunately, the documetation mixes naming conventions and this
             inconsistency creates confusion.
             
             frame = videoTime / videoRefreshPeriod
             
             @videoTimeScale = Units/second, used to convert videoTime into seconds
             and may also be used with videoRefreshPeriod to calculate the expected
             framesPerSecond.  I say expected, because videoTimeScale and
             videoRefreshPeriod don't change while videoTime does change.  Thus,
             to calculate fps in the case of system slow down, one would need to
             use videoTime with videoTimeScale to calculate the actual fps value.
             
             seconds = videoTime / videoTimeScale
             
             framesPerSecondConstant = videoTimeScale / videoRefreshPeriod (this value does not change if their is system slowdown)
             
             USE CASE 1: Time in DD:HH:mm:ss using hostTime
             let rootTotalSeconds = inNow.pointee.hostTime
             let rootDays = inNow.pointee.hostTime / (1_000_000_000 * 60 * 60 * 24) % 365
             let rootHours = inNow.pointee.hostTime / (1_000_000_000 * 60 * 60) % 24
             let rootMinutes = inNow.pointee.hostTime / (1_000_000_000 * 60) % 60
             let rootSeconds = inNow.pointee.hostTime / 1_000_000_000 % 60
             Swift.print("rootTotalSeconds: \(rootTotalSeconds) rootDays: \(rootDays) rootHours: \(rootHours) rootMinutes: \(rootMinutes) rootSeconds: \(rootSeconds)")
             
             USE CASE 2: Time in DD:HH:mm:ss using videoTime
             let totalSeconds = inNow.pointee.videoTime / Int64(inNow.pointee.videoTimeScale)
             let days = (totalSeconds / (60 * 60 * 24)) % 365
             let hours = (totalSeconds / (60 * 60)) % 24
             let minutes = (totalSeconds / 60) % 60
             let seconds = totalSeconds % 60
             Swift.print("totalSeconds: \(totalSeconds) Days: \(days) Hours: \(hours) Minutes: \(minutes) Seconds: \(seconds)")
             
             Swift.print("fps: \(Double(inNow.pointee.videoTimeScale) / Double(inNow.pointee.videoRefreshPeriod)) seconds: \(Double(inNow.pointee.videoTime) / Double(inNow.pointee.videoTimeScale))")
             */
            
            /*  The displayLinkContext in CVDisplayLinkOutputCallback's parameter list is the
             view being driven by the CVDisplayLink.  In order to use the context as an
             instance of SwiftOpenGLView (which has our drawView() method) we need to use
             unsafeBitCast() to cast this context to a SwiftOpenGLView.
             */
            
            if var context = linkContext?.load(as: Context.self) {
                
                let stamp  = inOutputTime.pointee
                let seconds:CFTimeInterval = CFTimeInterval(stamp.videoTime) / CFTimeInterval(stamp.videoTimeScale)
                
                //let time = CVTime(timeValue: stamp.videoTime, timeScale: stamp.videoTimeScale, flags: 0)
                
                context.handler(seconds)
                
                context.lastTime = seconds
                context.frameNumber += 1
                
                linkContext?.storeBytes(of:context,toByteOffset:0, as: Context.self)
            }
            
            
            //  We are going to assume that everything went well, and success as the CVReturn
            return kCVReturnSuccess
        }        
    }
#endif

