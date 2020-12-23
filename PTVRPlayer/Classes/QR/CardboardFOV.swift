//
//  FieldOfFiew.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/1/20.
//

import Foundation

public struct CardboardFieldOfView {
    
    public let angles: [Float]
    public let left: Float
    public let right: Float
    public let top: Float
    public let bottom: Float
    
    public init(angles: [Float]) {
        guard angles.count == 4 else {
            fatalError("FieldOfView expects four angles.")
        }
        self.angles = angles
        self.left = angles[0]
        self.right = angles[1]
        self.top = angles[2]
        self.bottom = angles[3]
    }
}
