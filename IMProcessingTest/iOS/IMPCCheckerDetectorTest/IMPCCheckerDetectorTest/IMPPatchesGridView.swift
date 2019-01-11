//
//  IMPPatchesGridView.swift
//  IMPCCheckerDetectorTest
//
//  Created by denis svinarchuk on 08.04.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class IMPPatchesGridView: UIView {
    
    var grid = IMPPatchesGrid() {
        didSet{
            updateGrid()
        }
    }
        
    lazy var skview:SKView = SKView(frame: self.bounds)
    lazy var scene:SKScene = SKScene(size: self.skview.bounds.size)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        
        skview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        skview.allowsTransparency = true
        skview.presentScene(scene)
        addSubview(skview)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for i in 0..<grid.target.count {
            let c = grid.target[i].center
            
            let postion = float2(c.x,1-c.y) * float2(bounds.width.float,bounds.height.float)
            let point = NSPoint(x: postion.x.cgfloat,
                                y: postion.y.cgfloat)
            
            if nodes.count > i {
                nodes[i].position = point
                nodes[i].setValue(SKAttributeValue(float: Float(nodeRadius)),
                                  forAttribute: "radius")
            }
        }
    }
    
    var nodeRadius:CGFloat {
        return skview.bounds.size.width/25
    }
    
    var nodes = [SKShapeNode]()
    
    func updateGrid()  {
        
        nodes.removeAll()
        scene.removeAllChildren()
        
        for i in 0..<grid.target.count {
            
            let c = grid.target[i].center
            
            let postion = float2(c.x,1-c.y) * float2(bounds.width.float,bounds.height.float)
            let point = NSPoint(x: postion.x.cgfloat,
                                y: postion.y.cgfloat)
            
            let node = SKShapeNode(circleOfRadius: nodeRadius)
            node.position = point
            
            node.fillColor = NSColor(rgb: grid.target[i].color)
            node.strokeColor = NSColor(rgb: float3(1) - grid.target[i].color)
            node.lineWidth = 4
            
            nodes.append(node)
            scene.addChild(node)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
