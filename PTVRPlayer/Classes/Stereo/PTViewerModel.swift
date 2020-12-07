//
//  PTViewerModel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

public enum PTViewerModel {
    case googleCardboard
    case custom(parameters: ViewerParametersProtocol)
}

extension PTViewerModel: ViewerParametersProtocol {
    private var parameters: ViewerParameters {
        switch self {
        case .googleCardboard:
            //            return ViewerParameters(
            //                lenses: Lenses(separation: 0.062, offset: 0.035, alignment: .bottom, screenDistance: 0.037),
            //                distortion: Distortion(k1: 0.26, k2: 0.27),
            //                maximumFieldOfView: FieldOfView(outer: 50.0, inner: 50.0, upper: 50.0, lower: 50.0)
            //            )
//            return ViewerParameters(
//                lenses: Lenses(separation: 0.064, offset: 0.035, alignment: .bottom, screenDistance: 0.039),
//                distortion: Distortion(k1: 0.34, k2: 0.55),
//                maximumFieldOfView: FieldOfView(outer: 60.0, inner: 60.0, upper: 60.0, lower: 60.0)
//            )
            return ViewerParameters(
                lenses: Lenses(separation: 0.060, offset: 0.035, alignment: .bottom, screenDistance: 0.048),
                distortion: Distortion(k1: 0.441, k2: 0.156),
                maximumFieldOfView: FieldOfView(outer: 40.0, inner: 40.0, upper: 40.0, lower: 40.0)
            )
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
