//
//  PTViewerModel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

public enum PTViewerModel {
    case cardboardJun2014
    case cardboardMay2015
    case vrShineCon
    case custom(parameters: ViewerParametersProtocol)
}

extension PTViewerModel: ViewerParametersProtocol {
    public var name: String {
        return parameters.name
    }
    
    private var parameters: ViewerParameters {
        switch self {
        case .cardboardJun2014:
            return ViewerParameters(
                name: "Cardboard Jun 2014",
                lenses: Lenses(separation: 0.060, offset: 0.035, alignment: .bottom, screenDistance: 0.042),
                distortion: Distortion(k1: 0.441, k2: 0.156),
                maximumFieldOfView: FieldOfView(outer: 40.0, inner: 40.0, upper: 40.0, lower: 40.0)
            )
        case .cardboardMay2015:
            return ViewerParameters(
                name: "Cardboard May 2015",
                lenses: Lenses(separation: 0.064, offset: 0.035, alignment: .bottom, screenDistance: 0.039),
                distortion: Distortion(k1: 0.34, k2: 0.55),
                maximumFieldOfView: FieldOfView(outer: 60.0, inner: 60.0, upper: 60.0, lower: 60.0)
            )
        case .vrShineCon:
            return ViewerParameters(
                name: "VR Shine Con",
                lenses: Lenses(separation: 0.060, offset: 0.035, alignment: .center, screenDistance: 0.062),
                distortion: Distortion(k1: 0.25, k2: 0.04),
                maximumFieldOfView: FieldOfView(outer: 50.0, inner: 50.0, upper: 50.0, lower: 50.0))
        case .custom(let parameters):
            return ViewerParameters(parameters)
        }
    }
    
    public var lenses: Lenses {
        return parameters.lenses
    }
    
    public var distortion: Distortion {
        return parameters.distortion
    }
    
    public var maximumFieldOfView: FieldOfView {
        return parameters.maximumFieldOfView
    }
}
