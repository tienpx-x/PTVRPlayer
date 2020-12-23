//
//  PTPlayer.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class PTPlayer: AVPlayer {
    var isSeekInProgress = false
    var chaseTime = CMTime.zero
    var playerCurrentItemStatus: AVPlayerItem.Status = .unknown
    
    override var rate: Float {
        set {
            super.rate = newValue
            isPlaying = newValue != 0
        }
        
        get {
            return super.rate
        }
    }
    
    var duration: TimeInterval {
        guard let currentItem = currentItem, !currentItem.duration.seconds.isNaN else { return 0 }
        return currentItem.duration.seconds
    }
    
    @objc dynamic var isPlaying: Bool = false
    
    func seek(to time: TimeInterval, completion: @escaping (Bool) -> Void) {
        var cmtime = CMTime(seconds: time, preferredTimescale: 100)
        if let maxTime = currentItem?.duration.seconds, time > maxTime {
            cmtime = CMTime(seconds: maxTime, preferredTimescale: 100)
        }
        
        DispatchQueue.main.async {
            self.seek(to: cmtime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: completion)
        }
    }
    
    deinit {
        print(String(describing: type(of: self)) + " deinit")
    }
}
