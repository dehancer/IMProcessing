//: Playground - noun: a place where people can play

import SpriteKit
import Cocoa
import PlaygroundSupport

//Create the SpriteKit View
let view:SKView = SKView(frame: CGRect(x:0, y:0, width:400, height:400))

//Add it to the TimeLine
PlaygroundPage.current.liveView = view

let scene:SKScene = SKScene(size: CGSize(width:1024, height:768))
scene.scaleMode = SKSceneScaleMode.aspectFit
view.presentScene(scene)

let redBox:SKSpriteNode = SKSpriteNode(color: SKColor.red, size:CGSize(width:20, height:20))
let greenBox:SKSpriteNode = SKSpriteNode(color: SKColor.green, size:CGSize(width:20, height:20))

let yellowCircle = SKShapeNode(circleOfRadius: 30)
yellowCircle.fillColor = SKColor.yellow
yellowCircle.strokeColor = SKColor.blue
yellowCircle.glowWidth = 4

scene.addChild(redBox)
scene.addChild(greenBox)
scene.addChild(yellowCircle)

redBox.size = CGSize(width:40, height:40)
redBox.position = CGPoint(x:30, y:30)
redBox.run(SKAction.repeatForever(SKAction.rotate(byAngle: 6, duration: 2)))


greenBox.size = CGSize(width:40, height:40)
greenBox.position = CGPoint(x:100, y:30)
greenBox.run(SKAction.repeatForever(SKAction.rotate(byAngle: 6, duration: 2)))

yellowCircle.position = CGPoint(x:200, y:30)
//yellowCircle.run(SKAction.repeatForever(SKAction.animate(withWarps: [SKWarpGeometry], times: [1])))
