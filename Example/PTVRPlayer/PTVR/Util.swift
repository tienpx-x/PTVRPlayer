//
//  Util.swift
//  Runner
//
//  Created by Phạm Xuân Tiến on 11/9/20.
//

// MARK: - Idle Timer
class Util {
    static func disableDeviceGoSleep() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    static func enableDeviceGoSleep() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

extension Util {
    static func getBottomSafeAreaPadding() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            return window?.safeAreaInsets.bottom ?? 0.0
        } else {
            return 0.0
        }
    }
    
    static func getTopSafeAreaPadding() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            return window?.safeAreaInsets.top ?? 0.0
        } else {
            return 0.0
        }
    }
    
    static func getLeftSafeAreaPadding() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            return window?.safeAreaInsets.left ?? 0.0
        } else {
            return 0.0
        }
    }
    
    static func getRightSafeAreaPadding() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            return window?.safeAreaInsets.right ?? 0.0
        } else {
            return 0.0
        }
    }
    
    static func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }

    static func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

    static func rad2deg(_ number: Float) -> Float {
        return number * 180 / .pi
    }

    static func deg2rad(_ number: Float) -> Float {
        return number * .pi / 180
    }
}
