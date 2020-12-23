//
//  UIDevice+Rx.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

extension Reactive where Base: UIDevice {
    var orientationChanged: Observable<UIDeviceOrientation> {
        return NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification)
        .map { _ in UIDevice.current.orientation }
    }
}
