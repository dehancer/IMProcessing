//
//  AppDelegate.swift
//  IMPPatchDetector
//
//  Created by denn on 07.07.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    lazy var openPanel:NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.resolvesAliases = true
        p.isExtensionHidden = false
        p.allowedFileTypes = [
            "jpg", "JPEG", "TIFF", "TIF", "PNG", "JPG", "dng", "DNG", "CR2", "ORF"
        ]
        return p
    }()
    
    @IBAction func openFile(_ sender: NSMenuItem) {
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path {
                (NSApplication.shared.keyWindow?.contentViewController as? ViewController)?.imagePath = path
            }
        }
    }
}

