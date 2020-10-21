//
//  PTMediaScene.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import SceneKit

public final class PT180SBSMediaNode: SCNNode {
    public var mediaContents: Any? {
        get {
            return geometry?.firstMaterial?.diffuse.contents
        }
        set(value) {
            geometry?.firstMaterial?.diffuse.contents = value
        }
    }
    
    public init(radius: CGFloat = 10, segmentCount: Int = 96) {
        super.init()
        name = "180 Object"
        _ = SCNSphere(radius: radius).then {
            $0.segmentCount = segmentCount
//            $0.firstMaterial?.cullMode = .front
            $0.firstMaterial?.isDoubleSided = true
            geometry = $0
        }
        scale = SCNVector3(x: 1, y: 1, z: -1)
        eulerAngles.y = deg2rad(-90)
        renderingOrder = .max
        
        // TODO: Blur Effect
//        if let image = UIImage(named: "blur", in: Bundle(for: type(of: self)), compatibleWith: nil) {
//            let sphere = SCNSphere(radius: 9.9).then {
//                $0.segmentCount = segmentCount
//                $0.firstMaterial?.cullMode = .front
//                $0.firstMaterial?.diffuse.contents = image
//            }
//            let overlayNode = SCNNode(geometry: sphere)
//            overlayNode.scale = SCNVector3(x: 1, y: 1, z: -1)
//            addChildNode(overlayNode)
//        }
        
        let ball = SCNPlane(width: 5, height: 3)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        let ballNode = SCNNode(geometry: ball)
        ballNode.eulerAngles.y = deg2rad(90)
        ballNode.eulerAngles.z = deg2rad(80)
        ballNode.position = SCNVector3Make(-2, -9, 0)
        addChildNode(ballNode)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
