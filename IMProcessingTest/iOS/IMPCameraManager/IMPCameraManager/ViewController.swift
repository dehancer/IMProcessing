//
//  ViewController.swift
//  DehancerI-CropEditor
//
//  Created by Denis Svinarchuk on 07/12/16.
//  Copyright © 2016 Dehancer. All rights reserved.
//

import UIKit
import IMProcessing
import SnapKit
import MetalPerformanceShaders


class BaseNavigationController: UINavigationController {

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
}


public class TestFilter: IMPFilter {
    
    class BlurFilter: IMPMPSUnaryKernelProvider {
        var name: String { return "BlurFilter" }
        func mps(device:MTLDevice) -> MPSUnaryImageKernel? {
            return MPSImageGaussianBlur(device: device, sigma: radius)
        }
        var radius:Float = 1
        var context: IMPContext?
        init(context:IMPContext?) {
            self.context = context
        }
    }

    lazy var mpsBlurFilter:BlurFilter = BlurFilter(context:self.context)

    lazy var impBlurFilter:IMPGaussianBlur = IMPGaussianBlur(context: self.context)
    
    public var blurRadius:Float = 0 {
        didSet{
            impBlurFilter.radius = blurRadius
            //mpsBlurFilter.radius = blurRadius
        }
    }
    
    public var inputEV:Float = 0 {
        didSet{ dirty = true }
    }
    
    public var inputExposure:Float = 0 {
        didSet{
            exposureFilter.setValue(inputExposure, forKey: "inputEV")
            dirty = true
        }
    }

    lazy var kernelEVBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    lazy var kernelEV:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: /*"kernel_Red"*/ "kernel_EV")
        f.optionsHandler = {  [unowned self] (kernel,commandEncoder,input,output) in
            var value  = self.inputEV
            var buffer = self.kernelEVBuffer
            memcpy(buffer.contents(), &value, buffer.length)
            commandEncoder.setBuffer(buffer, offset: 0, at: 0)
        }
        return f
    }()
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Test filter")
        super.configure()
        
        
        //add(function: kernelEV) { (source) in }
        
        //add(filter: exposureFilter)
        add(filter: impBlurFilter)
        //add(mps: mpsBlurFilter)
        //add(filter: xyderivative)
        //add(filter: nonMaximumSup)
    }

    private lazy var exposureFilter:CIFilter = CIFilter(name:"CIExposureAdjust")!
}


class ViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    let context = IMPContext(lazy: true)
    
    lazy var containerView:UIView = {
        let y = (self.navigationController?.navigationBar.bounds.height)! + UIApplication.shared.statusBarFrame.height
        let v = UIView(frame: CGRectMake( 0, y,
            self.view.bounds.size.width,
            self.view.bounds.size.height*3/4
            ))
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressHandler(gesture:)))
        press.minimumPressDuration = 0.05
        v.addGestureRecognizer(press)

        //let zoom = UIPinchGestureRecognizer(target: self, action: #selector(self.zoomHandler(sender:)))
        //v.addGestureRecognizer(zoom)

        return v
    }()
    
    lazy var liveView:IMPView = {
        let container = self.containerView.bounds
        let frame = CGRect(x: 0, y: 0,
                           width: container.size.width,
                           height: container.size.height)
        let v = IMPView(frame: frame, device: self.context.device)
        v.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        return v
    }()

    
    lazy var cameraManager:IMPCameraManager = {
        let c = IMPCameraManager(containerView: self.containerView)
        return c
    }()
    
    
    lazy var liveViewFilter:TestFilter = {
        let f = TestFilter(context: self.context)
        return f
    }()
    
    
    let blurSlider = UISlider()
    let evSlider = UISlider()
    let exposureSlider = UISlider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = NSColor.black
        self.view.insertSubview(containerView, at: 0)

        
        let triggerButton = UIButton(frame: CGRectMake(0, 0, 90, 90))
        
        triggerButton.backgroundColor = NSColor.clear
        
        triggerButton.setImage(NSImage(named: "shutterUp"), for: .normal)
        triggerButton.setImage(NSImage(named: "shutterDown"), for: .selected)
        triggerButton.setImage(NSImage(named: "shutterDown"), for: .highlighted)
        
        triggerButton.addTarget(self, action: #selector(self.capturePhoto(sender:)), for: .touchUpInside)
        view.addSubview(triggerButton)
        
        triggerButton.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-20)
            make.centerX.equalTo(view.snp.centerX).offset(0)
        }
        
        view.addSubview(blurSlider)
        blurSlider.value = 0
        blurSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp.topMargin).offset(20)
            make.left.equalTo(view.snp.left).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }

        blurSlider.addTarget(self, action: #selector(slideHandler(slider:)), for: .valueChanged)

        view.addSubview(evSlider)
        evSlider.value = 0
        evSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp.topMargin).offset(50)
            make.left.equalTo(view.snp.left).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }
        
        evSlider.addTarget(self, action: #selector(slideHandler(slider:)), for: .valueChanged)

        view.addSubview(exposureSlider)
        exposureSlider.value = 0
        exposureSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp.topMargin).offset(80)
            make.left.equalTo(view.snp.left).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }
        
        exposureSlider.addTarget(self, action: #selector(slideHandler(slider:)), for: .valueChanged)

        liveView.filter = liveViewFilter
        
        containerView.addSubview(liveView)
        
        NSLog("starting ...")
        
        liveView.viewReadyHandler = {
            NSLog("live view is ready ...")
        }
        
        cameraManager.add(streamObserver: { [unowned self] (camera, buffer) in
            if var image = self.liveView.filter?.source{
                image.update(buffer)
                self.liveView.filter?.source = image
            }
            else {
                self.liveView.filter?.source = IMPImage(context: self.liveView.context, image: buffer)
            }
        })
        
        cameraManager.start { (granted) -> Void in
            
            NSLog("started ...")
            
            if !granted {
                DispatchQueue.main.async{
                    
                    let alert = UIAlertController(
                        title:   "Camera is not granted",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
                    alert.addAction(cancelAction)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .default) { action -> Void in
                        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: { (completed) in
                                
                            })
                        }
                    }
                    alert.addAction(settingsAction)                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    func slideHandler(slider:UISlider)  {
        self.liveViewFilter.context.runOperation(.async) {
            if slider === self.evSlider {
                self.liveViewFilter.inputEV = slider.value * 3
            }
            else if slider === self.blurSlider {
                self.liveViewFilter.blurRadius = slider.value * 10
            }
            else if slider === self.exposureSlider {
                self.liveViewFilter.inputExposure = slider.value * 3
            }
        }
    }
    
    func pressHandler(gesture:UIPanGestureRecognizer) {
        if gesture.state == .began {
            liveViewFilter.enabled = false
        }
        else if gesture.state == .ended {
            liveViewFilter.enabled = true
        }
    }
    
    func capturePhoto(sender:UIButton)  {
        print("capture")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.resume()
    }
}
