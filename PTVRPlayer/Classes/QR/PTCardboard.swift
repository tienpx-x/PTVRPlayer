//
//  PTCardboard.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/23/20.
//

public class PTCardboard {
    public static func getViewerParam(url: String, onCompleted: @escaping (ViewerParameters) -> Void) {
        CardboardParams.fromUrl(url, onCompleted: { result in
            guard let cardboard = result.value else { return }
            guard cardboard.distortionCoefficients.count == 2 else { return }
            let data = ViewerParameters(
                name: cardboard.model,
                lenses: Lenses(separation: cardboard.interLensDistance,
                               offset: cardboard.verticalDistanceToLensCenter,
                               alignment: Lenses.Alignment(rawValue: Int(cardboard.verticalAlignment.rawValue)) ?? .bottom,
                               screenDistance: cardboard.screenToLensDistance),
                distortion: Distortion(k1: cardboard.distortionCoefficients[0], k2: cardboard.distortionCoefficients[1]),
                maximumFieldOfView: FieldOfView(outer: cardboard.leftEyeMaxFov.left,
                                                inner: cardboard.leftEyeMaxFov.right,
                                                upper: cardboard.leftEyeMaxFov.top,
                                                lower: cardboard.leftEyeMaxFov.bottom))
            onCompleted(data)
        })
    }
}
