//
//  InterfaceOrientation.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import UIKit

public protocol InterfaceOrientationProvider {
    func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation
}

extension UIInterfaceOrientation: InterfaceOrientationProvider {
    public func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return self
    }
}

extension UIApplication: InterfaceOrientationProvider {
    public func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return statusBarOrientation.interfaceOrientation(atTime: time)
    }
}

internal final class DefaultInterfaceOrientationProvider: InterfaceOrientationProvider {
    func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return UIApplication.shared.interfaceOrientation(atTime: time)
    }
}
