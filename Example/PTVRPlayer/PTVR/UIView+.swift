//
//  UIView+.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
