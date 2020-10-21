//
//  PTStereoCameraNode.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

import SceneKit

public final class PTStereoCameraNode: SCNNode {
    public var stereoParameters: StereoParametersProtocol {
        didSet {
            updatePointOfViews()
        }
    }

    public var nearZ: Float = 0.1 {
        didSet {
            updatePointOfViews()
        }
    }

    public var farZ: Float = 1000 {
        didSet {
            updatePointOfViews()
        }
    }

    private let pointOfViews: [Eye: SCNNode] = [
        .left: SCNNode(),
        .right: SCNNode()
    ]

    public init(stereoParameters: StereoParametersProtocol) {
        self.stereoParameters = stereoParameters
        super.init()
        updatePointOfViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func pointOfView(for eye: Eye) -> SCNNode {
        return pointOfViews[eye] ?? SCNNode()
    }

    private func updatePointOfViews() {
        let separation = stereoParameters.viewer.lenses.separation

        for (eye, node) in pointOfViews {
            var position = SCNVector3Zero

            switch eye {
            case .left:
                position.x = separation / -2
            case .right:
                position.x = separation / 2
            }

            node.position = position
            node.camera?.projectionTransform = stereoParameters.cameraProjectionTransform(for: eye, nearZ: nearZ, farZ: farZ)
        }
    }
}
