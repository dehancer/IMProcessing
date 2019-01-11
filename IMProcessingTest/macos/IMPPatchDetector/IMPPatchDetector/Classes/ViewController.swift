//
//  ViewController.swift
//  IMPPatchDetector
//
//  Created by denn on 07.07.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit

class ViewController: NSViewController {
    
    let context = IMPContext()
    
    var imagePath:String? {
        didSet{
            if let path = imagePath {
                filter.source = IMPImage(context: context, path: path)
            }
        }
    }
    
    //
    // Just redirect image rendering to IMPFilterView
    //
    lazy var filter:IMPFilter = {
        
        let checkerDetector = IMPCCheckerDetector(context: self.context, maxSize:800)
        let linesDetector   = IMPOrientedLinesDetector(context: self.context, maxSize: 800)
        
        linesDetector.linesMax = 20
        
        let renderer = IMPFilter(context: self.context)
        
        renderer
            // add debug info
            .extendName(suffix: "ViewController filter")
            //
            // add source image frame redirection to next filter
            // (multiplex operation)
            //
            .addRedirection(to: checkerDetector)
            //
            // add processing action to redirected filter
            //
            .addProcessing { destination in
                guard let size = destination.size else { return }

                DispatchQueue.main.async {
                    // set absolute size of image to right scale of view canvas
                    self.markersView.imageSize = size
                    // set corners
                    self.markersView.corners = checkerDetector.corners
                    
                    // draw patches
                    self.gridView.grid = checkerDetector.patchGrid
                }
        }
        
        renderer
            //
            // Now add redirection to process oriented lines
            //
            .addRedirection(to: linesDetector)
            //
            // add processing stage without action, only process result of redirection
            //
            .addProcessing()
            //
            // add observing result of processing in the Hough lines detector
            //
            .addObserver(lines: { (hlines, vlines, size) in
                DispatchQueue.main.async {
                    self.markersView.imageSize = size
                    self.markersView.hlines = hlines
                    self.markersView.vlines = vlines
                }
        })
        
        return renderer
    }()
    
    lazy var targetView:IMPFilterView = {
        let v = IMPFilterView()
        v.filter = self.filter
        return v
    }()
    
    lazy var markersView:MarkersView = {
        let v = MarkersView(frame:self.view.bounds)
        
        v.wantsLayer = true
        v.frame = self.targetView.bounds
        v.layer?.backgroundColor = NSColor.clear.cgColor
        v.autoresizingMask = [.width, .height]
        
        return v
    }()
    
    lazy var gridView:PatchesGridView = PatchesGridView(frame: self.view.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(targetView)
        targetView.addSubview(markersView)
        targetView.addSubview(gridView)
        
        targetView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(20)
        }
        
        gridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

