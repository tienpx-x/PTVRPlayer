//
//  PT180SBSVideoScene.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import SceneKit
import Metal
import AVFoundation

protocol PTVideoSceneDelegate: NSObject {
    func render(_ scene: SCNScene, atTime time: TimeInterval, forEye eye: Eye)
}

public class PT180SBSVideoScene: SCNScene {
    // SceneKit
    public lazy var mediaNode: PT180SBSMediaNode = {
        return PT180SBSMediaNode().then {
            rootNode.addChildNode($0)
        }
    }()
    
    // Delegate
    weak var delegate: PTVideoSceneDelegate?
    
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
    
    public var playerItem: AVPlayerItem? {
        return player?.currentItem
    }
    
    public lazy var textureCache: CVMetalTextureCache = {
        var cacheOutput: CVMetalTextureCache?
        let code = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cacheOutput)
        
        guard let cache = cacheOutput else {
            fatalError("Failed to create cached")
        }
        return cache
    }()
    
    public lazy var videoOutput: AVPlayerItemVideoOutput = {
        var settings: [String: Any] = [
            (kCVPixelBufferMetalCompatibilityKey as String): true,
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        return AVPlayerItemVideoOutput(outputSettings: settings)
    }()
    
    
    private var playerTexture: MTLTexture? {
        didSet {
            mediaNode.mediaContents = playerTexture
        }
    }
    
    // Timer
    private lazy var renderLoop: PTRenderLoop = {
        return PTRenderLoop { [weak self] time in
            guard let self = self else { return }
            self.renderVideo(atTime: time)
        }
    }()
    
    private let commandQueue: MTLCommandQueue
    
    public override var isPaused: Bool {
        didSet {
            if isPaused {
                renderLoop.pause()
            } else {
                renderLoop.resume()
            }
        }
    }
    
    public let device: MTLDevice
    public let eye: Eye
    public let orientationNode: PTOrientationNode
    
    public init(device: MTLDevice, eye: Eye = .left, orientationNode: PTOrientationNode) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Must have a command queue")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.orientationNode = orientationNode
        self.eye = eye
        super.init()
        renderLoop.resume()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - AVPlayer Render
extension PT180SBSVideoScene {
    private func updateTextureIfNeeded() {
        guard let videoSize = playerItem?.presentationSize, videoSize != .zero else { return }
        let width = Int(videoSize.width)
        let height = Int(videoSize.height)
        if let texture = playerTexture, texture.width == width, texture.height == height { return }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: true)
        playerTexture = device.makeTexture(descriptor: descriptor)
    }
    
    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard hasNewPixelBuffer(atHostTime: time) else { return }
        updateTextureIfNeeded()
        guard let texture = playerTexture else { return }
        do {
            guard let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer() else {
                fatalError("Can't render without a command buffer")
            }
            try render(atHostTime: time, to: texture, commandBuffer: commandBuffer)
            commandBuffer.commit()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - AVPlayer Item Render
extension PT180SBSVideoScene {
    private func bind(_ player: AVPlayer) {
        guard let playerItem = playerItem, !playerItem.outputs.contains(videoOutput) else {
            return
        }
        playerItem.add(videoOutput)
    }
    
    private func unbind(_ player: AVPlayer) {
        guard let playerItem = playerItem, playerItem.outputs.contains(videoOutput) else {
            return
        }
        playerItem.remove(videoOutput)
    }
    
    public func hasNewPixelBuffer(atItemTime time: CMTime) -> Bool {
        return videoOutput.hasNewPixelBuffer(forItemTime: time)
    }
    
    public func updateOrientation(_ time: TimeInterval) {
        var disableActions = false
        
        if let provider = orientationNode.deviceOrientationProvider, provider.shouldWaitDeviceOrientation(atTime: time) {
            provider.waitDeviceOrientation(atTime: time)
            disableActions = true
        }
        
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1 / 15
        SCNTransaction.disableActions = disableActions
        
        orientationNode.updateDeviceOrientation(atTime: time)
        
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
    
    public func render(atItemTime time: CMTime, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        var cacheOutput: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, texture.pixelFormat, texture.width, texture.height, 0, &cacheOutput)
        
        guard let cvMetalTexture = cacheOutput else {
            fatalError("cvMetalTexture")
        }
        
        guard let sourceTexture = CVMetalTextureGetTexture(cvMetalTexture) else {
            fatalError("Failed to get MTLTexture from CVMetalTexture")
        }
        
        let sourceOrigin: MTLOrigin
        let sourceSize: MTLSize
        let destinationOrigin: MTLOrigin
        
        switch eye {
        case .left:
            sourceOrigin = MTLOriginMake(0, 0, 0)
            sourceSize = MTLSizeMake(sourceTexture.width / 2, sourceTexture.height, sourceTexture.depth)
            destinationOrigin = MTLOriginMake(0, 0, 0)
        case .right:
            sourceOrigin = MTLOriginMake(sourceTexture.width / 2, 0, 0)
            sourceSize = MTLSizeMake(sourceTexture.width / 2, sourceTexture.height, sourceTexture.depth)
            destinationOrigin = MTLOriginMake(0, 0, 0)
        }
        
        guard let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
            fatalError("blitCommandEncoder")
        }
        
        blitCommandEncoder.copy(from: sourceTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: sourceOrigin,
                                sourceSize: sourceSize,
                                to: texture,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: destinationOrigin)
        blitCommandEncoder.endEncoding()
    }
    
    public func hasNewPixelBuffer(atHostTime time: TimeInterval) -> Bool {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        return hasNewPixelBuffer(atItemTime: itemTime)
    }
    
    public func render(atHostTime time: TimeInterval, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        updateOrientation(time)
        try? render(atItemTime: itemTime, to: texture, commandBuffer: commandBuffer)
        delegate?.render(self, atTime: time, forEye: eye)
    }
}

