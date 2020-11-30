//
//  PTStereoView.swift
//  Device
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

import UIKit
import SceneKit
import AVFoundation

public final class StereoView: UIView {
    // MARK: - Properties
    
    public var scene: SCNScene? {
        didSet {
            leftOrientationNode.removeFromParentNode()
            rightOrientationNode.removeFromParentNode()
            scene?.rootNode.addChildNode(leftOrientationNode)
            scene?.rootNode.addChildNode(rightOrientationNode)
            stereoScene.scene = scene
        }
    }
    
    public lazy var leftOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.pointOfView.addChildNode(self.leftStereoCameraNode)
        node.interfaceOrientationProvider = UIInterfaceOrientation.landscapeRight
        node.updateInterfaceOrientation()
        return node
    }()
    
    public lazy var rightOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.position = SCNVector3Make(0, -20, 0)
        node.pointOfView.addChildNode(self.rightStereoCameraNode)
        node.interfaceOrientationProvider = UIInterfaceOrientation.landscapeRight
        node.updateInterfaceOrientation()
        return node
    }()
    
    public lazy var leftStereoCameraNode: PTStereoCameraNode = {
        let node = PTStereoCameraNode(stereoParameters: self.stereoParameters)
        node.position = SCNVector3(0, 0.1, -0.08)
        return node
    }()
    
    public lazy var rightStereoCameraNode: PTStereoCameraNode = {
        let node = PTStereoCameraNode(stereoParameters: self.stereoParameters)
        node.position = SCNVector3(0, 0.1, -0.08)
        return node
    }()
    
    public let stereoTexture: MTLTexture
    public let device: MTLDevice
    
    public var stereoParameters = StereoParameters(screen: PTScreenModel(),
                                                   viewer: PTViewerModel.googleCardboard)
    
    public lazy var stereoScene: PTStereoScene = {
        let scene = PTStereoScene(device: device)
        scene.stereoTexture = stereoTexture
        scene.stereoParameters = stereoParameters
        scene.leftOrientationNode = self.leftOrientationNode
        scene.rightOrientationNode = self.rightOrientationNode
        scene.setPointOfView(leftStereoCameraNode.pointOfView(for: .left), for: .left)
        scene.setPointOfView(rightStereoCameraNode.pointOfView(for: .right), for: .right)
        return scene
    }()
    
    public lazy var scnView: SCNView = {
        return SCNView(frame: bounds, options: [
            SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue,
            SCNView.Option.preferredDevice.rawValue: device
        ]).then {
            $0.scene = stereoScene
            $0.delegate = self
            $0.pointOfView = stereoScene.pointOfView
            $0.backgroundColor = .black
            $0.isUserInteractionEnabled = false
            $0.isPlaying = true
            addSubview($0)
        }
    }()
    
    // Gesture
    
    public lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        self.addGestureRecognizer(recognizer)
        return recognizer
    }()
    
    // MARK: - Life Cycle
    
    public init(device: MTLDevice) {
        self.device = device
        // Init Texture
        let nativeScreenSize = UIScreen.main.nativeLandscapeBounds.size
        let textureSize = nativeScreenSize
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            mipmapped: true
        )
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Can't continue without a view")
        }
        self.stereoTexture = texture
        super.init(frame: UIScreen.main.landscapeBounds)
        let sceneScale = textureSize.width / (bounds.width * UIScreen.main.scale)
        scnView.transform = CGAffineTransform(scaleX: sceneScale, y: sceneScale)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        scnView.frame = bounds
    }
    
    deinit {
        leftOrientationNode.removeFromParentNode()
        rightOrientationNode.removeFromParentNode()
        print(String(describing: type(of: self)) + " deinit")
    }
}
extension StereoView: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let commandQueue = renderer.commandQueue else {
            fatalError("Invalid rendering API")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.stereoScene.render(atHostTime: time, commandQueue: commandQueue)
        }
    }
}
