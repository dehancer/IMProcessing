//: [Previous](@previous)

import SpriteKit
import SceneKit
import Cocoa
import PlaygroundSupport

class View:NSView {
    lazy var sceneView:SCNView = SCNView(frame:self.bounds)
    
    let scene = SCNScene()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override required init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(sceneView)
        
        sceneView.scene = scene
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0.0, y: 0.0, z: 3.0)
        
        let light = SCNLight()
        light.type = SCNLight.LightType.omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
        
        let cubeGeometry = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)
        let cubeNode = SCNNode(geometry: cubeGeometry)
        
        let planeGeometry = SCNPlane(width: 40.0, height: 40.0)
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.eulerAngles = SCNVector3(x: CGFloat(GLKMathDegreesToRadians(-90)), y: 0, z: 0)
        planeNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        
        
        let sphereGeometry = SCNSphere(radius: 1.5)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = NSColor.green
        sphereGeometry.materials = [sphereMaterial]
        
        var sphere1 = SCNNode(geometry: sphereGeometry)
        
        
        let shape = SCNPhysicsShape(geometry: sphereGeometry, options: nil)
        let sphere1Body = SCNPhysicsBody(type: .kinematic, shape: shape)
        sphere1.physicsBody = sphere1Body
        
        sphere1 = SCNNode(geometry: sphereGeometry)
        sphere1.position = SCNVector3(x: 5, y: 1.5, z: 0)
        
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cubeNode)
        scene.rootNode.addChildNode(sphere1)
        scene.rootNode.addChildNode(planeNode)
        
        cameraNode.position = SCNVector3(x: -3.0, y: 3.0, z: 3.0)
        
        
        let constraint = SCNLookAtConstraint(target: cubeNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        let press = NSPressGestureRecognizer(target: self, action: #selector(scenePressed(recognizer:)))
        
        sceneView.addGestureRecognizer(press)

    }

    @objc func scenePressed(recognizer: NSPressGestureRecognizer) {        
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        NSLog("--> \(location, hitResults)")
        if hitResults.count > 0 {
            let result = hitResults[0] 
            let node = result.node
            node.removeFromParentNode()
        }
    }
    
}

let view = View(frame:  CGRect(x:0, y:0, width:500, height:500))

PlaygroundPage.current.liveView = view

//: [Next](@next)
