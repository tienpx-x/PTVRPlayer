//
//  PTPTStereoView.swift
//  Device
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

import UIKit
import SceneKit
import AVFoundation

public final class PTStereoView: UIView {
    // MARK: - Properties
    
    public var scene: PT180SBSVideoScene? {
        didSet {
            leftOrientationNode.removeFromParentNode()
            rightOrientationNode.removeFromParentNode()
            scene?.rootNode.addChildNode(leftOrientationNode)
            scene?.rootNode.addChildNode(rightOrientationNode)
            stereoScene.scene = scene
            renderControllerObject()
        }
    }
    
    public var renderController: [PTRenderObject] = []
    private var renderControllerForRightEye: [PTRenderObject] = []
    
    // Touch + Focus
    
    public lazy var touchView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    }()
    
    // Controller Properties
    private var currentFocus: PTRenderObject?
    private var currentFocused: PTRenderObject?
    var currentFocusTime: Double = 0
    var focusBottomTime: Double = 0
    var unFocusControllerTime: Double = 0
    var totalFocusTime: Double = 100
    var totalFocusBottomTime: Double = 150
    var totalUnFocusControllerTime: Double = 400
    
    public var isControllerVisible = false
    
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
    public var stereoParameters = StereoParameters(screen: PTScreenModel(), viewer: PTViewerModel.cardboardMay2015)
    
    public lazy var stereoScene: PTStereoScene = {
        let scene = PTStereoScene(device: device)
        scene.stereoTexture = stereoTexture
        scene.stereoParameters = stereoParameters
        scene.leftOrientationNode = self.leftOrientationNode
        scene.rightOrientationNode = self.rightOrientationNode
        let leftPOV = leftStereoCameraNode.pointOfView(for: .left)
        let rightPOV = rightStereoCameraNode.pointOfView(for: .right)
        scene.setPointOfView(leftPOV, for: .left)
        scene.setPointOfView(rightPOV, for: .right)
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
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
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
        initCursor()
    }
    
    deinit {
        leftOrientationNode.fullResetRotation()
        rightOrientationNode.fullResetRotation()
        leftOrientationNode.removeFromParentNode()
        rightOrientationNode.removeFromParentNode()
        renderController.forEach {
            $0.removeFromParentNode()
        }
        renderControllerForRightEye.forEach {
            $0.removeFromParentNode()
        }
        print(String(describing: type(of: self)) + " deinit")
    }
}

// MARK: Render List
extension PTStereoView {
    public func renderControllerObject() {
        guard let scene = scene else { return }
        renderController.forEach {
            scene.leftMediaNode.addChildNode($0)
            let rightNodes = $0.clone()
            renderControllerForRightEye.append(rightNodes)
            scene.rightMediaNode.addChildNode(rightNodes)
        }
        hideController()
        leftOrientationNode.delegate = self
        rightOrientationNode.delegate = self
    }
    
    public func removeControllerObject() {
        renderController.forEach {
            $0.removeFromParentNode()
        }
        renderControllerForRightEye.forEach {
            $0.removeFromParentNode()
        }
    }
    
    public func resetController() {
        renderControllerObject()
        touchView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        initCursor()
    }
}

// MARK: Touching
extension PTStereoView {
    func initCursor() {
        addGestureRecognizer(tapGestureRecognizer)
        // Add 3D Touch
        leftOrientationNode.setCursorView(view: touchView)
        rightOrientationNode.setCursorView(view: touchView)
        hideController()
    }
    
    func showTouch() {
        touchView.isHidden = false
    }
    
    func hideTouch() {
        touchView.isHidden = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        
    }
}

extension PTStereoView: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let commandQueue = renderer.commandQueue else {
            fatalError("Invalid rendering API")
        }
        DispatchQueue.main.async {
            self.stereoScene.render(atHostTime: time, commandQueue: commandQueue)
            if #available(iOS 11.0, *) {
                self.detection()
            }
        }
    }
    
    @available(iOS 11.0, *)
    func detection() {
        guard isControllerVisible else { return }
        DispatchQueue.main.async {
            guard let physicsWorld = self.stereoScene.leftSCNRenderer.scene?.physicsWorld else { return }
            guard let cursorBody = self.leftOrientationNode.cursorNode.physicsBody else { return }
            let contacts = physicsWorld.contactTest(with: cursorBody, options: nil)
            let hitResults = contacts.filter({ $0.nodeB.name != "Base Object" })
            guard !hitResults.isEmpty else {
                self.currentFocused = nil
                self.currentFocusTime = 0
                self.setNonFocusCursor()
                return
            }
            self.handleContact(result: hitResults[0])
        }
    }
    
    func handleContact(result: SCNPhysicsContact) {
        guard let scene = scene else { return }
        guard let node = result.nodeB as? PTRenderObject else { return }
        if node.canFocused && self.currentFocused != node {
            print("[XXX] \(scene.rootNode.convertPosition(result.contactPoint, to: node))")
            // Change cursor
            self.setFocusCursor()
            node.focusAction?()
            // Action
            if self.currentFocus == node {
                if self.currentFocusTime == self.totalFocusTime {
                    switch node.type {
                    case .button:
                        node.action?(nil)
                        self.currentFocused = node
                        self.currentFocus = nil
                        self.currentFocusTime = 0
                    case .slider(let duration):
                        let position = scene.rootNode.convertPosition(result.contactPoint, to: node).x
                        var percent: Float = 0
                        let start: Float = -0.24
                        let end: Float = 0.24
                        if(position == 0) {
                            percent = 50
                        } else if(position > 0 ) {
                            percent = (position / end) * 50 + 50
                        } else  if(position < 0 ) {
                            percent = 50 - (position / start) * 50
                        }
                        let seekTime: TimeInterval = (duration / 100) * Double(percent)
                        node.action?(seekTime)
                        self.currentFocused = node
                        self.currentFocus = nil
                        self.currentFocusTime = 0
                    default:
                        break
                    }
                }
                self.currentFocusTime += 1
            } else {
                self.currentFocus = node
                self.currentFocusTime = 0
            }
        } else {
            self.setNonFocusCursor()
        }
    }
    
    func setNonFocusCursor() {
        DispatchQueue.main.async {
            self.touchView.do {
                $0.isOpaque = false
                $0.subviews.forEach {
                    $0.removeFromSuperview()
                }
                let focusView = UIView(frame: CGRect(x: 4, y: 4, width: 2, height: 2))
                focusView.backgroundColor = .white
                focusView.layer.cornerRadius = 1
                $0.addSubview(focusView)
            }
            self.renderController.forEach {
                $0.childNodes.forEach { node in
                    guard let node = node as? PTRenderObject else { return }
                    node.unFocusAction?()
                }
            }
            self.renderControllerForRightEye.forEach {
                $0.childNodes.forEach { node in
                    guard let node = node as? PTRenderObject else { return }
                    node.unFocusAction?()
                }
            }
            if self.isControllerVisible {
                self.unFocusControllerTime += 1
            }
        }
    }
    
    func setFocusCursor() {
        DispatchQueue.main.async {
            self.touchView.do {
                $0.isOpaque = false
                $0.subviews.forEach {
                    $0.removeFromSuperview()
                }
                let focusView = CircularProgressView(frame: $0.bounds)
                focusView.progressColor = .white
                focusView.trackColor = .clear
                focusView.value = CGFloat(self.currentFocusTime / self.totalFocusTime)
                $0.addSubview(focusView)
            }
            self.unFocusControllerTime = 0
        }
    }
}

// MARK: - 3D Node
extension PTStereoView {
    public func hideController() {
        hideTouch()
        isControllerVisible = false
        [leftOrientationNode, rightOrientationNode].forEach {
            $0?.cursorNode.isHidden = true
        }
    }
    
    public func showController() {
        showTouch()
        isControllerVisible = true
        [leftOrientationNode, rightOrientationNode].forEach {
            $0?.cursorNode.isHidden = false
        }
    }
}

extension PTStereoView: PTOrientationDelegate {
    public func didInRangeHorizontal(orientationNode: PTOrientationNode) {
        
    }
    
    public func didMaxLeftHorizontal(orientationNode: PTOrientationNode) {
        
    }
    
    public func didMaxRightHorizontal(orientationNode: PTOrientationNode) {
        
    }
    
    public func didInRangeVertical(orientationNode: PTOrientationNode) {
        focusBottomTime = 0
        if isControllerVisible {
            if unFocusControllerTime >= totalUnFocusControllerTime {
                unFocusControllerTime = 0
                hideController()
            }
        }
        
        if !isControllerVisible {
            renderController.forEach { $0.opacity = 0 }
            renderControllerForRightEye.forEach { $0.opacity = 0 }
        }
    }
    
    public func didMaxTopVertical(orientationNode: PTOrientationNode) {
        
    }
    
    public func didMaxBottomVertical(orientationNode: PTOrientationNode) {
        // Controller
        if focusBottomTime >= totalFocusBottomTime {
            renderController.forEach { $0.opacity = 1 }
            renderControllerForRightEye.forEach { $0.opacity = 1 }
            showController()
        } else {
            if !isControllerVisible {
                renderController.forEach { $0.opacity = CGFloat(focusBottomTime / totalFocusBottomTime) }
                renderControllerForRightEye.forEach { $0.opacity = CGFloat(focusBottomTime / totalFocusBottomTime) }
            }
        }
        focusBottomTime += 1
    }
}
