//
//  PTRenderObject.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 12/3/20.
//

import SceneKit

public enum PTRenderType {
    case button
    case slider(TimeInterval)
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
