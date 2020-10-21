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
    
    public let player: AVPlayer
    public let stereoTexture: MTLTexture
    public let device: MTLDevice
    
    public var stereoParameters = StereoParameters(screen: PTScreenModel(),
                                                   viewer: PTViewerModel.googleCardboard)
    
    lazy var stereoScene: PTStereoScene = {
        let scene = PTStereoScene(device: device)
        scene.stereoTexture = stereoTexture
        scene.stereoParameters = stereoParameters
        scene.player = player
        return scene
    }()
    
    public lazy var scnView: SCNView = {
        return SCNView(frame: bounds, options: [
            SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue,
            SCNView.Option.preferredDevice.rawValue: device
        ]).then {
            $0.scene = stereoScene
            $0.pointOfView = stereoScene.pointOfView
            $0.backgroundColor = .black
            $0.isUserInteractionEnabled = false
            $0.isPlaying = true
            insertSubview($0, at: 0)
        }
    }()
    
    // Gesture
    
    public lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        self.addGestureRecognizer(recognizer)
        return recognizer
    }()
    
    // MARK: - Life Cycle
    
    public init(device: MTLDevice, player: AVPlayer) {
        self.player = player
        self.device = device
        // Init Tex
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
        print(String(describing: type(of: self)) + " deinit")
    }
}
