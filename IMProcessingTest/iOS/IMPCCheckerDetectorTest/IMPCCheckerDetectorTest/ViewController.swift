//
//  ViewController.swift
//  IMPCChekerTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import UIKit
import SnapKit

class BaseNavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

class ViewController: UIViewController {

    var gridView = IMPPatchesGridView(frame:CGRect(x: 0, y: 0, width: 100, height: 100))

    let context = IMPContext(lazy: true)
    
    lazy var containerView:UIView = {
        let y = (self.navigationController?.navigationBar.bounds.height)! + UIApplication.shared.statusBarFrame.height
        let v = UIView(frame: CGRect(x: 0, y: y, width: self.view.bounds.size.width, height: self.view.bounds.size.height*3/4))
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
    
    lazy var liveViewFilter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        
        f.add(filter:self.crossHairs)
        return f
    }()
    
    lazy var detector:IMPCCheckerDetector = {
        let f = IMPCCheckerDetector(context: IMPContext())
        f.maxSize = 400
        return f
    }()

    
    lazy var canny:IMPCannyEdges = IMPCannyEdges(context: self.context)
    lazy var harris:IMPHarrisCornerDetector = IMPHarrisCornerDetector(context: IMPContext())
    
    lazy var crossHairs:IMPCrosshairsGenerator = IMPCrosshairsGenerator(context: self.context)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = NSColor.black
        self.view.insertSubview(containerView, at: 0)
        
        detector.maxSize = 800
        harris.maxSize = 400
        
        liveViewFilter => detector --> { (destination) in
            DispatchQueue.main.async {
                guard let size = destination.size else { return }
                self.crossHairs.points = self.detector.corners
                self.gridView.grid = self.detector.patchGrid
            }
        }
        
        
        liveView.filter = liveViewFilter
        
        containerView.addSubview(liveView)
                
        liveView.viewReadyHandler = {
            NSLog("live view is ready ...")
        }
        
        liveView.addSubview(gridView)
        
        gridView.snp.makeConstraints { (make) in
            make.left.equalTo(gridView.superview!).offset(0)
            make.right.equalTo(gridView.superview!).offset(0)
            make.top.equalTo(gridView.superview!).offset(0)
            make.bottom.equalTo(gridView.superview!).offset(0)
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

