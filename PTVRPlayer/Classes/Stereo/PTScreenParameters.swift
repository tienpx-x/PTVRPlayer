//
//  PTScreenParameters.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

public protocol ScreenParametersProtocol {
    var width: Float { get }  // The long edge of the device.
    var height: Float { get } // The short edge of the device.
    var border: Float { get } // Distance from bottom of the cardboard to the bottom edge of screen.
}

public struct ScreenParameters: ScreenParametersProtocol {
    public var width: Float
    public var height: Float
    public var border: Float

    public init(width: Float, height: Float, border: Float) {
        self.width = width
        self.height = height
        self.border = border
    }

    public init(_ parameters: ScreenParametersProtocol) {
        self.width = parameters.width
        self.height = parameters.height
        self.border = parameters.border
    }
}

extension ScreenParametersProtocol {
    public var aspectRatio: Float {
        return width / height
    }
}
