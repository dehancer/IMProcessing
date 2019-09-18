//
//  AppDelegate.swift
//  IMPColorSpacesTest
//
//  Created by Denis Svinarchuk on 03/05/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let spline = IMPCubicSpline(resolution: 256);
        spline.controls = [float2(0,0), float2(0.1,0.2), float2(0.9,0.5), float2(1,1)];
        
        Swift.print("! matlab bezier spline... ")
        Swift.print("x=[", separator: "", terminator: "")
        for x in stride(from: Float(0.0), to: Float(1.0), by: spline.step) {
            Swift.print("\(x) ", separator: "", terminator: "")
        }
        Swift.print("]; ")
        Swift.print("y=[", separator: "", terminator: "")
        for x in stride(from: Float(0.0), to: Float(1.0), by: spline.step) {
            let y = spline.value(at: x)
            Swift.print("\(y) ", separator: "", terminator: "")
        }
        Swift.print("];")
        Swift.print("plot(x,y);")
        
        //Swift.print("matrix: \(spline.matrix)")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

