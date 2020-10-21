//
//  UIScreen+.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/29/20.
//

extension UIScreen {
    var landscapeBounds: CGRect {
        return CGRect(x: 0, y: 0, width: fixedCoordinateSpace.bounds.height, height: fixedCoordinateSpace.bounds.width)
    }

    var nativeLandscapeBounds: CGRect {
        return CGRect(x: 0, y: 0, width: nativeBounds.height, height: nativeBounds.width)
    }
}
