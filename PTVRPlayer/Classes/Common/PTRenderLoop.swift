//
//  PTRenderLoop.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import QuartzCore

public final class PTRenderLoop {
    public let queue: DispatchQueue
    
    private lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: RunLoop.Mode.common)
        link.isPaused = true
        return link
    }()
    
    public var isPaused: Bool {
        return displayLink.isPaused
    }
    
    private let action: (TimeInterval) -> Void

    public init(queue: DispatchQueue = DispatchQueue(label: "PTVRPlayer.RenderLoop"), action: @escaping (_ targetTime: TimeInterval) -> Void) {
        self.queue = queue
        self.action = action
    }
    
    public func pause() {
        displayLink.isPaused = true
    }
    
    public func resume() {
        displayLink.isPaused = false
    }
    
    @objc private func handleDisplayLink(_ sender: CADisplayLink) {
        let time: TimeInterval
        if #available(iOS 10, *) {
            time = sender.targetTimestamp
        } else {
            time = sender.timestamp + sender.duration
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            self.action(time)
        }
    }
}

