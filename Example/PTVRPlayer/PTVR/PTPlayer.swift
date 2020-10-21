//
//  PTPlayer.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class PTPlayer: AVPlayer {
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

    deinit {
        print(String(describing: type(of: self)) + " deinit")
    }
}
