//
//  PTTouchModel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/11/20.
//

import UIKit

public class PTTouchModel {
    let frame = UIScreen.main.bounds
    
    var cursor: CGPoint {
        switch Device.version() {
        case .iPhone6, .iPhone6S, .iPhone7, .iPhone8, .iPhoneSE2: // 4.7 inch
            return CGPoint(x: 310, y: 380)
        case .iPhone12Mini: //  5.4 inch
            // TODO
            return CGPoint(x: 300, y: 380)
        case .iPhone6Plus, .iPhone6SPlus, .iPhone7Plus, .iPhone8Plus: // 5.5 inch
            return CGPoint(x: 435, y: 545)
        case .iPhoneX,.iPhoneXS,.iPhone11Pro: // 5.8 inch
            return CGPoint(x: 660, y: 605)
        case .iPhone11, .iPhoneXR: // 6.1 inch
            // TODO
            return CGPoint(x: 488, y: 420)
        case  .iPhone12, .iPhone12Pro: // 6.1 inch bigger
            // TODO
            return CGPoint(x: 690, y: 590)
        case .iPhoneXS_Max,.iPhone11Pro_Max: // 6.5 inch
            return CGPoint(x: 725, y: 620)
        case .iPhone12Pro_Max: // 6.7 inch
            // TODO
            return CGPoint(x: 705, y: 640)
        default:
            return CGPoint(x: 0, y: 0)
        }
    }
    
    var rotateCenter: Float {
        return 0
    }
    
    var leftCenter: CGPoint {
        switch Device.version() {
        case .iPhoneXS_Max,.iPhone11Pro_Max:
            return CGPoint(x: frame.size.width  * 0.28, y: frame.size.height / 2) // 896, 414 - 250, 207
        case .iPhone11, .iPhone12, .iPhone12Pro: // 6.1 inch
            // TODO
            return CGPoint(x: frame.size.width  * 0.28, y: frame.size.height / 2)
        default:
            return CGPoint(x: frame.size.width  * 0.25, y: frame.size.height / 2)
        }
    }
    
    var rightCenter: CGPoint {
        switch Device.version() {
        case .iPhoneXS_Max,.iPhone11Pro_Max:
            return CGPoint(x: frame.size.width  * 0.718, y: frame.size.height / 2)
        case .iPhone11, .iPhone12, .iPhone12Pro: // 6.1 inch
            // TODO
            return CGPoint(x: frame.size.width  * 0.718, y: frame.size.height / 2)
        default:
            return CGPoint(x: frame.size.width  * 0.75, y: frame.size.height / 2)
        }
    }
}

