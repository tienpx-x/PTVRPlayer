//
//  PTStereoScene.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

import SceneKit
import Metal
import AVFoundation

class EyeRenderingConfiguration {
    let texture: MTLTexture
    var pointOfView: SCNNode?

    init(texture: MTLTexture) {
        self.texture = texture
    }
}

public class PTStereoScene: SCNScene {
    // SceneKit
    public lazy var leftOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.allowsUserRotation = false
        node.fieldOfView = 85
        node.interfaceOrientationProvider = UIInterfaceOrientation.landscapeRight
        node.updateInterfaceOrientation()
        return node
    }()
    
    public lazy var rightOrientationNode: PTOrientationNode = {
        let node = PTOrientationNode()
        node.allowsUserRotation = false
        node.fieldOfView = 85
        node.interfaceOrientationProvider = UIInterfaceOrientation.landscapeRight
        node.updateInterfaceOrientation()
        return node
    }()
    
    public lazy var leftEyeScene: PT180SBSVideoScene = {
        let scene = PT180SBSVideoScene(device: device, eye: .left, orientationNode: leftOrientationNode)
        scene.rootNode.addChildNode(leftOrientationNode)
        scene.delegate = self
        return scene
    }()
    
    public lazy var rightEyeScene: PT180SBSVideoScene = {
        let scene = PT180SBSVideoScene(device: device, eye: .right, orientationNode: rightOrientationNode)
        scene.rootNode.addChildNode(rightOrientationNode)
        scene.delegate = self
        return scene
    }()
    
    public lazy var leftEyeRenderer: SCNRenderer = {
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = leftEyeScene
        return renderer
    }()
    
    public lazy var rightEyeRenderer: SCNRenderer = {
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = rightEyeScene
        return renderer
    }()
    
    // Render
    public var player: AVPlayer? {
        willSet {
            if let player = player {
                unbind(player)
            }
        }
        didSet {
            if let player = player {
                bind(player)
            }
        }
    }
    
    var stereoTexture: MTLTexture? {
        didSet {
            guard let stereoTexture = stereoTexture else { return }
            attachTextureToMesh()
            let eyeTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: stereoTexture.pixelFormat,
                width: stereoTexture.width / 2,
                height: stereoTexture.height,
                mipmapped: true
            )
            eyeTextureDescriptor.usage = .renderTarget
            
            guard let leftTexture = device.makeTexture(descriptor: eyeTextureDescriptor), let rightTexture = device.makeTexture(descriptor: eyeTextureDescriptor) else {
                fatalError("Left and Right Textures are needed.")
            }
            
            eyeRenderingConfigurations = [
                .left: EyeRenderingConfiguration(texture: leftTexture),
                .right: EyeRenderingConfiguration(texture: rightTexture)
            ]
        }
    }
    
    var stereoParameters: StereoParametersProtocol? {
        didSet {
            guard let parameters = stereoParameters else {
                return
            }
            updateMesh(with: parameters)
            attachTextureToMesh()
        }
    }
    
    // Scene
    
    lazy var pointOfView: SCNNode = {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 0.5
        camera.zNear = 0
        
        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 0, 0.01)
        rootNode.addChildNode(node)
        return node
    }()
    
    private lazy var meshNode: SCNNode = {
        let node = SCNNode()
        rootNode.addChildNode(node)
        return node
    }()
    
    private let renderSemaphore = DispatchSemaphore(value: 6)
    private var eyeRenderingConfigurations: [Eye: EyeRenderingConfiguration] = [:]
    
    public let device: MTLDevice
    
    public init(device: MTLDevice) {
        self.device = device
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print(String(describing: type(of: self)) + " deinit")
    }
}

// MARK: - Mesh
extension PTStereoScene {
    func attachTextureToMesh() {
//        meshNode.geometry?.firstMaterial?.diffuse.contents = stereoTexture
    }
    
    func updateMesh(with parameters: StereoParametersProtocol, width: Int = 40, height: Int = 40) {
        let (vertices, texcoord) = computeMeshPoints(with: parameters, width: width, height: height)
        let colors = computeMeshColors(width: width, height: height)
        let indices = computeMeshIndices(width: width, height: height)
        
        let mesh = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(texcoord: texcoord),
                SCNGeometrySource(colors: colors)
            ],
            elements: [
                SCNGeometryElement(indices: indices, primitiveType: .triangles)
            ]
        )
        
        let material = SCNMaterial()
        material.isDoubleSided = true
        mesh.materials = [material]
        
        meshNode.geometry = mesh
    }
}

// MARK: - AVPlayer Item Render
extension PTStereoScene {
    private func bind(_ player: AVPlayer) {
        leftEyeScene.player = player
        rightEyeScene.player = player
    }
    
    private func unbind(_ player: AVPlayer) {
        leftEyeScene.player = nil
        rightEyeScene.player = nil
    }
}

// MARK: - PTVideoSceneDelegate
extension PTStereoScene: PTVideoSceneDelegate {
    func render(_ scene: SCNScene, atTime time: TimeInterval, forEye eye: Eye) {
        guard let stereoTexture = stereoTexture else { return }
        guard let configuration = eyeRenderingConfigurations[eye] else { return }
        let scnRenderer: SCNRenderer
        
        switch eye {
        case .left:
            scnRenderer = leftEyeRenderer
        case .right:
            scnRenderer = rightEyeRenderer
        }

        guard let commandBuffer = scnRenderer.commandQueue?.makeCommandBuffer() else {
            fatalError("Can't render without a command buffer")
        }

        let texture = configuration.texture
        let viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = texture
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].loadAction = .clear

        scnRenderer.render(atTime: time, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: passDescriptor)

        let destinationOrigin: MTLOrigin
        switch eye {
        case .left:
            destinationOrigin = MTLOrigin(x: 0, y: 0, z: 0)
        case .right:
            destinationOrigin = MTLOrigin(x: stereoTexture.width / 2, y: 0, z: 0)
        }

        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder?.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: texture.width, height: texture.height, depth: texture.depth),
            to: stereoTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: destinationOrigin
        )
        blitCommandEncoder?.endEncoding()
        
        commandBuffer.commit()
    }
}
