//
//  AppDelegate.swift
//  IMPFilterObservers
//
//  Created by denis svinarchuk on 25/10/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func openFile(_ sender: NSMenuItem) {
        viewController?.openFilePanel()
    }
    
    var viewController:ViewController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
       viewController = NSApp.keyWindow?.contentViewController as? ViewController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

