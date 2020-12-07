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
    var scene: PT180SBSVideoScene? {
        get {
            return leftSCNRenderer.scene as? PT180SBSVideoScene
        }
        set(value) {
            leftSCNRenderer.scene = value
            rightSCNRenderer.scene = value
        }
    }

    var leftOrientationNode: PTOrientationNode?
    var rightOrientationNode: PTOrientationNode?
    
    public lazy var leftSCNRenderer: SCNRenderer = {
        return SCNRenderer(device: device, options: nil)
    }()
    
    public lazy var rightSCNRenderer: SCNRenderer = {
        return SCNRenderer(device: device, options: nil)
    }()
    
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
        meshNode.geometry?.firstMaterial?.diffuse.contents = stereoTexture
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

// MARK: - Render
extension PTStereoScene {
    public func setPointOfView(_ pointOfView: SCNNode?, for eye: Eye) {
        eyeRenderingConfigurations[eye]?.pointOfView = pointOfView
        switch eye {
        case .left:
            leftSCNRenderer.pointOfView = pointOfView
        case .right:
            rightSCNRenderer.pointOfView = pointOfView
        }
    }
    
    func pointOfView(for eye: Eye) -> SCNNode? {
        return eyeRenderingConfigurations[eye]?.pointOfView
    }
    
    public func updateOrientation(_ time: TimeInterval) {
        guard let leftOrientationNode = leftOrientationNode else { return}
        guard let rightOrientationNode = rightOrientationNode else { return}
        
        var disableActions = false
        if let provider = leftOrientationNode.deviceOrientationProvider,
            provider.shouldWaitDeviceOrientation(atTime: time) {
            provider.waitDeviceOrientation(atTime: time)
            disableActions = true
        }
        
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1 / 15
        SCNTransaction.disableActions = disableActions
        
        leftOrientationNode.updateDeviceOrientation(scene: self, atTime: time, node: scene?.leftMediaNode, forEye: .left)
        rightOrientationNode.updateDeviceOrientation(scene: self, atTime: time, node: scene?.rightMediaNode, forEye: .right)
        
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
}

// MARK: - PTVideoSceneDelegate
extension PTStereoScene {
    public func render(atHostTime time: TimeInterval,
                       commandQueue: MTLCommandQueue) {
        updateOrientation(time)
        guard let stereoTexture = stereoTexture else { return }
        let semaphore = renderSemaphore
        for (eye, configuration) in eyeRenderingConfigurations {
            semaphore.wait()
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                fatalError("Can't render without a command buffer")
            }
            
            let texture = configuration.texture
            let viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)
            print("[LOG] VIEWPORT: \(viewport)")
            
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = texture
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            passDescriptor.colorAttachments[0].storeAction = .store
            passDescriptor.colorAttachments[0].loadAction = .clear
                        
            switch eye {
            case .left:
                leftSCNRenderer.render(atTime: time,
                                       viewport: viewport,
                                       commandBuffer: commandBuffer,
                                       passDescriptor: passDescriptor)
            case .right:
                rightSCNRenderer.render(atTime: time,
                                        viewport: viewport,
                                        commandBuffer: commandBuffer,
                                        passDescriptor: passDescriptor)
            }

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
            
            commandBuffer.addCompletedHandler { _ in
                semaphore.signal()
            }
            
            commandBuffer.commit()
        }
    }
}
