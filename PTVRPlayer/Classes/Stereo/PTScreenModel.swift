//
//  PTScreenModel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//
import UIKit
import Device

public class PTScreenModel: ScreenParametersProtocol {
    private var parameters: ScreenParameters {
        switch Device.version() {
        case .iPhone4:
            return ScreenParameters(width: 0.075, height: 0.050, border: 0.0045)
        case .iPhone5:
            return ScreenParameters(width: 0.089, height: 0.050, border: 0.0045)
        case .iPhone6,.iPhone7,.iPhone8,.iPhone11:
            return ScreenParameters(width: 0.104, height: 0.058, border: 0.005)
        case .iPhone6Plus:
            return ScreenParameters(width: 0.112, height: 0.064, border: 0.005)
        case .iPhoneX,.iPhoneXS:
            return ScreenParameters(width: 0.120, height: 0.06, border: 0.005)
        case .iPhoneXS_Max,.iPhone11Pro_Max:
            return ScreenParameters(width: 0.122, height: 0.06, border: 0.005)
        default:
            return ScreenParameters(width: 0.112, height: 0.064, border: 0.005)
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
