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
    
    public lazy var leftTouchView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    }()
    
    public lazy var rightTouchView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    }()
    
    // Controller Properties
    private let touchModel = PTTouchModel()
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
            print($0.center)
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
    func renderControllerObject() {
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
}

// MARK: Touching
extension PTStereoView {
    func initCursor() {
        addGestureRecognizer(tapGestureRecognizer)
        leftTouchView.center = touchModel.leftCenter;
        addSubview(leftTouchView)
        rightTouchView.center = touchModel.rightCenter;
        addSubview(rightTouchView)
        hideTouch()
    }
    
    func showTouch() {
        leftTouchView.isHidden = false
        rightTouchView.isHidden = false
    }
    
    func hideTouch() {
        leftTouchView.isHidden = true
        rightTouchView.isHidden = true
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
            let sceneRenderer = self.stereoScene.leftSCNRenderer
            let centerPoint = self.touchModel.cursor
            let hits = sceneRenderer.hitTest(centerPoint, options: [.searchMode : 1])
            guard hits.count > 0 else { return }
            let hitResults = hits.filter({ $0.node.name != "Base Object" })
            guard !hitResults.isEmpty else {
                self.currentFocused = nil
                self.currentFocusTime = 0
                self.setNonFocusCursor()
                return
            }
            hitResults.forEach { result in
                guard let node = result.node as? PTRenderObject else { return }
                if node.canFocused && self.currentFocused != node {
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
                                let position = result.localCoordinates.x
                                var percent: Float = 0
                                let start: Float = -0.22495809
                                let end: Float = 0.22489665
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
        }
    }
    
    func setNonFocusCursor() {
        [leftTouchView, rightTouchView].forEach {
            $0.subviews.forEach {
                $0.removeFromSuperview()
            }
            let focusView = UIView(frame: CGRect(x: 4, y: 4, width: 2, height: 2))
            focusView.backgroundColor = .white
            focusView.layer.cornerRadius = 1
            $0.addSubview(focusView)
        }
        renderController.forEach {
            $0.childNodes.forEach { node in
                guard let node = node as? PTRenderObject else { return }
                node.unFocusAction?()
            }
        }
        renderControllerForRightEye.forEach {
            $0.childNodes.forEach { node in
                guard let node = node as? PTRenderObject else { return }
                node.unFocusAction?()
            }
        }
        if isControllerVisible {
            unFocusControllerTime += 1
        }
    }
    
    func setFocusCursor() {
        [leftTouchView, rightTouchView].forEach {
            $0.subviews.forEach {
                $0.removeFromSuperview()
            }
            let focusView = CircularProgressView(frame: $0.bounds)
            focusView.progressColor = .white
            focusView.trackColor = .clear
            focusView.value = CGFloat(self.currentFocusTime / self.totalFocusTime)
            $0.addSubview(focusView)
        }
        unFocusControllerTime = 0
    }
}

// MARK: - 3D Node
extension PTStereoView {
    public func hideController() {
        hideTouch()
        isControllerVisible = false
    }
    
    public func showController() {
        showTouch()
        isControllerVisible = true
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
