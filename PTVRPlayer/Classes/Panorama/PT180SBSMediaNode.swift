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
    
    var radius: CGFloat
    var segmentCount: Int
    
    public init(radius: CGFloat = 10, segmentCount: Int = 96) {
        self.radius = radius
        self.segmentCount = segmentCount
        super.init()
        name = "Base Object"
        _ = SCNSphere(radius: radius).then {
            $0.segmentCount = segmentCount
            $0.firstMaterial?.cullMode = .front
            geometry = $0
        }
        scale = SCNVector3(x: 1, y: 1, z: -1)
        eulerAngles.y = deg2rad(-180)
        renderingOrder = .max
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addEffect(image: UIImage) {
        DispatchQueue.main.async {
            let sphereEffect = SCNTube(innerRadius: self.radius - 0.02,
                                       outerRadius: self.radius - 0.01,
                                       height: 1).then {
                $0.firstMaterial?.cullMode = .front
                $0.firstMaterial?.diffuse.contents = image.cgImage
            }
            let effectNode = SCNNode(geometry: sphereEffect)
            effectNode.eulerAngles.x = deg2rad(90)
            effectNode.eulerAngles.y = deg2rad(-90)
            self.addChildNode(effectNode)
        }
    }
}
