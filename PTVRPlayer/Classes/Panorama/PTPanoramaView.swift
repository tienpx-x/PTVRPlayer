//
//  PTPanoramaView.swift
//  Device
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import UIKit
import SceneKit
import Metal
import Then
import AVFoundation

public final class PTPanoramaView: UIView {
    // MARK: - Properties
    
    // Metal
    
    public lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()
    
    //SceneKit View
    
    public var scene: PT180SBSVideoScene? {
        get {
            return scnView.scene as? PT180SBSVideoScene
        }
        set(value) {
            leftOrientationNode.removeFromParentNode()
            rightOrientationNode.removeFromParentNode()
            value?.rootNode.addChildNode(leftOrientationNode)
            value?.rootNode.addChildNode(rightOrientationNode)
            scnView.scene = value
        }
    }
    
    public lazy var scnView: SCNView = {
        return SCNView(frame: bounds, options: [
            SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue,
            SCNView.Option.preferredDevice.rawValue: device
        ]).then {
            $0.backgroundColor = .black
            $0.isUserInteractionEnabled = false
            $0.pointOfView = leftOrientationNode.pointOfView
            $0.isPlaying = true
            insertSubview($0, at: 0)
        }
    }()
    
    // Gesture
    
    public lazy var leftOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.fieldOfView = 120
        node.allowsUserRotation = true
        node.pointOfView.camera?.categoryBitMask = CategoryBitMask.all.subtracting(.rightEye).rawValue
        let lockDegree = Float(45)
        node.maximumVerticalRotationAngle = deg2rad(lockDegree)
        node.maximumHorizontalRotationAngle = deg2rad(lockDegree)
        return node
    }()
    
    public lazy var rightOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.fieldOfView = 120
        node.allowsUserRotation = true
        node.pointOfView.camera?.categoryBitMask = CategoryBitMask.all.subtracting(.leftEye).rawValue
        let lockDegree = Float(45)
        node.maximumVerticalRotationAngle = deg2rad(lockDegree)
        node.maximumHorizontalRotationAngle = deg2rad(lockDegree)
        node.position = SCNVector3Make(0, -20, 0)
        return node
    }()
    
    public lazy var panGestureManager: PTPanoramaPanGestureManager = {
        let manager = PTPanoramaPanGestureManager(rotationNode: leftOrientationNode.userRotationNode)
        let lockDegree = Float(45)
        manager.minimumVerticalRotationAngle = -deg2rad(lockDegree)
        manager.maximumVerticalRotationAngle = deg2rad(lockDegree)
        manager.minimumHorizontalRotationAngle = -deg2rad(lockDegree)
        manager.maximumHorizontalRotationAngle = deg2rad(lockDegree)
        return manager
    }()
    
    // MARK: - Life Cycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        scnView.frame = bounds
    }
    
    deinit {
        print(String(describing: type(of: self)) + " deinit")
    }
}

// MARK: - Video Player
extension PTPanoramaView {
    public func load(player: AVPlayer, format: PTMediaFormat) {
        switch format {
        case .stereoSBS:
            let scene = PT180SBSVideoScene(device: device,
                                           leftOrientationNode: leftOrientationNode,
                                           rightOrientationNode: rightOrientationNode)
            scene.player = player
            self.scene = scene
        }
    }
}
 

// MARK: - Controller
extension PTPanoramaView {
    public func addControl(view: UIView) {
        self.addSubview(view)
        let recognizer = AdvancedPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        recognizer.earlyTouchEventHandler = { [weak self] in
            guard let self = self else { return }
            self.panGestureManager.stopAnimations()
            self.panGestureManager.resetReferenceAngles()
        }
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(recognizer)
    }
    
    @objc public func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        panGestureManager.handlePanGesture(sender)
    }
    
    @objc public func setNeedsResetRotation(animated: Bool = false) {
        panGestureManager.stopAnimations()
        leftOrientationNode.setNeedsResetRotation(animated: animated)
    }
}

extension PTPanoramaView {
    public func startRender() {
        scene?.isPaused = false
    }
    
    public func stopRender() {
        scene?.isPaused = true
    }
}
