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
            $0.firstMaterial?.cullMode = .front
            geometry = $0
        }
        scale = SCNVector3(x: 1, y: 1, z: -1)
        eulerAngles.y = deg2rad(-90)
        renderingOrder = .max
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
