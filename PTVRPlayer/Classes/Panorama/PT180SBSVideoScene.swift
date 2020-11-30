//
//  PT180SBSVideoScene.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import SceneKit
import Metal
import AVFoundation

public protocol PTVideoSceneDelegate: NSObject {
    func render(atHostTime time: TimeInterval, commandBuffer: MTLCommandBuffer)
}

public class PT180SBSVideoScene: SCNScene {
    // SceneKit
    public lazy var leftMediaNode: PT180SBSMediaNode = {
        return PT180SBSMediaNode().then {
            rootNode.addChildNode($0)
        }
    }()
    
    public lazy var rightMediaNode: PT180SBSMediaNode = {
        return PT180SBSMediaNode().then {
            rootNode.addChildNode($0)
            $0.position = SCNVector3Make(0, -20, 0)
        }
    }()
    
    // Delegate
    public weak var delegate: PTVideoSceneDelegate?
    
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
    
    
    private var leftPlayerTexture: MTLTexture? {
        didSet {
            leftMediaNode.mediaContents = leftPlayerTexture
        }
    }
    
    private var rightPlayerTexture: MTLTexture? {
        didSet {
            rightMediaNode.mediaContents = rightPlayerTexture
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
    public let leftOrientationNode: PTOrientationNode
    public let rightOrientationNode: PTOrientationNode
    
    public init(device: MTLDevice, eye: Eye = .left, leftOrientationNode: PTOrientationNode, rightOrientationNode: PTOrientationNode) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Must have a command queue")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.leftOrientationNode = leftOrientationNode
        self.rightOrientationNode = rightOrientationNode
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
        if let leftTexture = leftPlayerTexture,
            let rightTexture = rightPlayerTexture,
            leftTexture.width == width,
            leftTexture.height == height,
            rightTexture.width == width,
            rightTexture.height == height { return }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: true)
        leftPlayerTexture = device.makeTexture(descriptor: descriptor)
        rightPlayerTexture = device.makeTexture(descriptor: descriptor)
    }
    
    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard hasNewPixelBuffer(atHostTime: time) else { return }
        updateTextureIfNeeded()
        guard let _ = leftPlayerTexture, let _ = rightPlayerTexture else { return }
        guard let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer() else {
            fatalError("Can't render without a command buffer")
        }
        try? render(atHostTime: time, commandBuffer: commandBuffer)
        commandBuffer.commit()
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
        
        if let provider = leftOrientationNode.deviceOrientationProvider, provider.shouldWaitDeviceOrientation(atTime: time) {
            provider.waitDeviceOrientation(atTime: time)
            disableActions = true
        }
        
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1 / 15
        SCNTransaction.disableActions = disableActions
        
        leftOrientationNode.updateDeviceOrientation(atTime: time)
        rightOrientationNode.updateDeviceOrientation(atTime: time)
        
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
    
    public func render(atItemTime time: CMTime, commandBuffer: MTLCommandBuffer) throws {
        guard let leftTexture = leftPlayerTexture, let rightTexture = rightPlayerTexture else { return }
        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        var cacheOutput: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, leftTexture.pixelFormat, leftTexture.width, leftTexture.height, 0, &cacheOutput)
        
        guard let cvMetalTexture = cacheOutput else {
            fatalError("cvMetalTexture")
        }
        
        guard let sourceTexture = CVMetalTextureGetTexture(cvMetalTexture) else {
            fatalError("Failed to get MTLTexture from CVMetalTexture")
        }
        
        let lSourceOrigin = MTLOriginMake(0, 0, 0)
        let lSourceSize = MTLSizeMake(sourceTexture.width / 2, sourceTexture.height, sourceTexture.depth)
        let lDestinationOrigin = MTLOriginMake(0, 0, 0)
        let rSourceOrigin = MTLOriginMake(sourceTexture.width / 2, 0, 0)
        let rSourceSize = MTLSizeMake(sourceTexture.width / 2, sourceTexture.height, sourceTexture.depth)
        let rDestinationOrigin = MTLOriginMake(0, 0, 0)
        
        guard let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
            fatalError("blitCommandEncoder")
        }
        
        blitCommandEncoder.copy(from: sourceTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: lSourceOrigin,
                                sourceSize: lSourceSize,
                                to: leftTexture,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: lDestinationOrigin)
        blitCommandEncoder.copy(from: sourceTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: rSourceOrigin,
                                sourceSize: rSourceSize,
                                to: rightTexture,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: rDestinationOrigin)
        blitCommandEncoder.endEncoding()
        
    }
    
    public func hasNewPixelBuffer(atHostTime time: TimeInterval) -> Bool {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        return hasNewPixelBuffer(atItemTime: itemTime)
    }
    
    public func render(atHostTime time: TimeInterval, commandBuffer: MTLCommandBuffer) throws {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        updateOrientation(time)
        try? render(atItemTime: itemTime, commandBuffer: commandBuffer)
//        delegate?.render(atHostTime: time, commandBuffer: commandBuffer)
    }
}

