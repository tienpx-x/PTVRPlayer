//
//  PTScreenModel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//
import UIKit

public class PTScreenModel: ScreenParametersProtocol {
    private var parameters: ScreenParameters {
        switch Device.version() {
        case .iPhone6, .iPhone6S, .iPhone7, .iPhone8, .iPhoneSE2: // 4.7 inch
            return ScreenParameters(width: 0.102, height: 0.058, border: 0.005)
        case .iPhone12Mini: //  5.4 inch
            // TODO
            return ScreenParameters(width: 0, height: 0, border: 0)
        case .iPhone6Plus, .iPhone6SPlus, .iPhone7Plus, .iPhone8Plus: // 5.5 inch
            return ScreenParameters(width: 0.110, height: 0.065, border: 0.005)
        case .iPhoneX,.iPhoneXS,.iPhone11Pro: // 5.8 inch
            return ScreenParameters(width: 0.134, height: 0.06, border: 0.005)
        case .iPhone11, .iPhoneXR: // 6.1 inch
            // TODO
            return ScreenParameters(width: 0.134, height: 0.06, border: 0.005)
        case  .iPhone12, .iPhone12Pro: // 6.1 inch bigger
            // TODO
            return ScreenParameters(width: 0.134, height: 0.06, border: 0.005)
        case .iPhoneXS_Max,.iPhone11Pro_Max: // 6.5 inch
            return ScreenParameters(width: 0.134, height: 0.06, border: 0.005)
        case .iPhone12Pro_Max: // 6.7 inch
            // TODO
            return ScreenParameters(width: 0.134, height: 0.06, border: 0.005)
        default:
            return ScreenParameters(width: 0, height: 0, border: 0)
        }
    }
    
    public var width: Float {
        return parameters.width
    }
    
    public var height: Float {
        return parameters.height
    }
    
    public var border: Float {
        return parameters.border
    }
}
