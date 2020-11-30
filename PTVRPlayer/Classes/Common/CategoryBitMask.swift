//
//  PTCategoryBitMask.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/1/20.
//

import SceneKit

public struct CategoryBitMask: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension CategoryBitMask {
    public static let all = CategoryBitMask(rawValue: .max)
    public static let leftEye = CategoryBitMask(rawValue: 1 << 21)
    public static let rightEye = CategoryBitMask(rawValue: 1 << 22)
}

