//
//  ViewController.swift
//  IMPFilterObservers
//
//  Created by denis svinarchuk on 25/10/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import SnapKit


class ViewController: NSViewController {
    
    var context = IMPContext()
    lazy var filter     = IMPGaussianBlur(context: self.context)    
    lazy var filter2    = IMPFilter(context: self.context)    
    lazy var filter3    = IMPFilter(context: self.context)    
    lazy var imageView  = IMPView(frame: self.view.bounds, device: self.context.device)
            
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
       
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
            
        imageView.filter = filter                
        imageView.filter = filter2                
        imageView.filter = filter3               
        imageView.filter = filter  
        
        imageView.filter?.addObserver(newSource: sourceObserver)
        imageView.filter?.addObserver(newSource: sourceObserver)
        imageView.filter?.addObserver(newSource: sourceObserver2)
        
        imageView.filter?.addObserver(dirty: dirtyObserver)
        imageView.filter?.addObserver(dirty: dirtyObserver)
        imageView.filter?.addObserver(dirty: dirtyObserver)
    }
        
    
    @nonobjc lazy var sourceObserver:IMPFilter.SourceUpdateHandler = {
        let handler:IMPFilter.SourceUpdateHandler = { source in
            Swift.print("source2 = \(String(describing: source))")
        }
        return handler
    }()
    
    
    lazy var sourceObserver2:IMPFilter.SourceUpdateHandler = {
        let handler:IMPFilter.SourceUpdateHandler = { source in
            Swift.print("source2 = \(String(describing: source))")
        }
        return handler
    }()
    
    private lazy var dirtyObserver:IMPFilter.FilterHandler = {
        let handler:IMPFilter.FilterHandler = { (filter, source, destintion) in
            let addr = unsafeBitCast(filter, to: Int.self)
            Swift.print("dirtyObserver source = \(String(describing: source)) destintion = \(destintion)")
        } 
        return handler
    }()
    
    
    public func openFilePanel(){
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles  = true;
        openPanel.resolvesAliases = true;
        openPanel.isExtensionHidden = false;
        openPanel.allowedFileTypes = ["jpg", "png", "ocr", "cr2", "tiff"]
        
        let result = openPanel.runModal()
        
        if result == NSApplication.ModalResponse.OK {
            let source = IMPImage(context: context, url: openPanel.urls[0])
            filter.source = source
        }
    }
}

