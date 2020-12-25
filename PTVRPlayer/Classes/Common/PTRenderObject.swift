//
//  PTRenderObject.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/3/20.
//

import SceneKit

public enum PTRenderType: Equatable {
    case button
    case slider(TimeInterval)
    case progress(TimeInterval)
    
    public static func ==(lhs: PTRenderType, rhs: PTRenderType) -> Bool {
        switch (lhs, rhs) {
        case (let .progress(_), let .progress(_)):
            return true
        default:
            return false
        }
    }
}

public class PTRenderObject: SCNNode {
    public var canFocused = false
    public var action: ((Any?) -> Void)? = nil
    public var focusAction: (() -> Void)? = nil
    public var unFocusAction: (() -> Void)? = nil
    public var type: PTRenderType = .button
    
    public override init() {
        super.init()
    }
    
    public init(geometry: SCNGeometry?) {
        super.init()
        self.geometry = geometry
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
