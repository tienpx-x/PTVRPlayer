//
//  PTPTOrientationNode.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import SceneKit
import CoreMotion

public class PTOrientationNode: SCNNode {
    public var maximumVerticalRotationAngle: Float?
    public var maximumHorizontalRotationAngle: Float?
    public var allowsUserRotation = true
    public var initialAttitude: CMAttitude?
    
    let userRotationNode = SCNNode()
    let referenceRotationNode = SCNNode()
    let deviceOrientationNode = SCNNode()
    let interfaceOrientationNode = SCNNode()
    
    public let pointOfView = SCNNode()
    
    public var fieldOfView: CGFloat = 90 {
        didSet {
            self.updateCamera()
        }
    }
    
    public var deviceOrientationProvider: DeviceOrientationProvider? = DefaultDeviceOrientationProvider()
    
    public var interfaceOrientationProvider: InterfaceOrientationProvider? = DefaultInterfaceOrientationProvider()
    
    public override init() {
        super.init()
        
        userRotationNode.name = "UserRotationNode"
        referenceRotationNode.name = "ReferenceRotationNode"
        deviceOrientationNode.name = "DeviceOrientationNode"
        interfaceOrientationNode.name = "InterfaceOrientationNode"
        pointOfView.name = "PointOfView"
        
        addChildNode(userRotationNode)
        userRotationNode.addChildNode(referenceRotationNode)
        referenceRotationNode.addChildNode(deviceOrientationNode)
        deviceOrientationNode.addChildNode(interfaceOrientationNode)
        interfaceOrientationNode.addChildNode(pointOfView)
        
        let camera = SCNCamera()
        camera.zNear = 0.3
        pointOfView.camera = camera
        
        updateCamera()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateDeviceOrientation(atTime time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let deviceRotation = deviceOrientationProvider?.deviceOrientation(atTime: time) else {
            return
        }
        if allowsUserRotation {
            // TODO: Lock device orientation
//            if let initialAttitude = initialAttitude {
//                let userEulerAngle = userRotationNode.eulerAngles
//                var roll = initialAttitude.roll - deviceRotation.attitude.roll
//                var yaw = initialAttitude.yaw - deviceRotation.attitude.yaw
//                var pitch = initialAttitude.pitch - deviceRotation.attitude.pitch
//                print("Change \(rad2deg(yaw)) - \(rad2deg(roll)) - \(rad2deg(pitch))")
//
//                var angleX = Float(pitch) + userEulerAngle.x
//                if let maximum = maximumVerticalRotationAngle {
//                    angleX = min(angleX, maximum)
//                } else {
//                    angleX = Float(pitch)
//                }
//
//                var angleY = Float(roll) + userEulerAngle.y
//                if let maximum = maximumHorizontalRotationAngle {
//                    angleY = min(angleY, maximum)
//                } else {
//                    angleY = Float(roll)
//                }
//                deviceOrientationNode.eulerAngles.x = angleX
//                deviceOrientationNode.eulerAngles.y = angleY
//            } else {
//                initialAttitude = deviceRotation.attitude
//            }
        } else {
            deviceOrientationNode.orientation = deviceRotation.rotation.scnQuaternion
        }
        //        deviceOrientationNode.orientation = rotation.scnQuaternion
        //        var angleX = eulerAngles.x
        //        if let maximum = maximumVerticalRotationAngle {
        //            angleX = min(angleX, maximum)
        //        }
        //        eulerAngles.x = angleX
        //
        //        var angleY = eulerAngles.y
        //        if let maximum = maximumHorizontalRotationAngle {
        //            angleY = min(angleY, maximum)
        //        }
        //        eulerAngles.y = angleY
        
        //        deviceOrientationNode.eulerAngles = eulerAngles
    }
    
    public func updateInterfaceOrientation(atTime time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let interfaceOrientation = interfaceOrientationProvider?.interfaceOrientation(atTime: time) else {
            return
        }
        
        var rotation = Rotation()
        
        switch interfaceOrientation {
        case .portraitUpsideDown:
            rotation.rotate(byZ: .pi)
        case .landscapeLeft:
            rotation.rotate(byZ: .pi / 2)
        case .landscapeRight:
            rotation.rotate(byZ: .pi / -2)
        default:
            break
        }
        
        interfaceOrientationNode.orientation = rotation.scnQuaternion
        
        if #available(iOS 11, *) {
            let cameraProjectionDirection: SCNCameraProjectionDirection
            
            switch interfaceOrientation {
            case .landscapeLeft, .landscapeRight:
                cameraProjectionDirection = .vertical
            default:
                cameraProjectionDirection = .horizontal
            }
            
            pointOfView.camera?.projectionDirection = cameraProjectionDirection
        }
    }
    
    public func resetRotation() {
        let r1 = Rotation(pointOfView.presentation.worldTransform).inverted()
        let r2 = Rotation(referenceRotationNode.presentation.worldTransform)
        let r3 = r1 * r2
        referenceRotationNode.transform = r3.scnMatrix4
        userRotationNode.transform = SCNMatrix4Identity
    }
    
    public func resetRotation(animated: Bool, completionHanlder: (() -> Void)? = nil) {
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0, 0, 1)
        SCNTransaction.completionBlock = completionHanlder
        SCNTransaction.disableActions = !animated
        
        resetRotation()
        
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
    
    public func setNeedsResetRotation(animated: Bool) {
        let action = SCNAction.run { node in
            guard let node = node as? PTOrientationNode else { return }
            node.resetRotation(animated: animated)
        }
        runAction(action, forKey: "setNeedsResetRotation")
    }
    
    private func updateCamera() {
        guard let camera = self.pointOfView.camera else {
            return
        }
        
        if #available(iOS 11, *) {
            camera.fieldOfView = fieldOfView
        } else {
            camera.xFov = Double(fieldOfView)
            camera.yFov = Double(fieldOfView)
        }
    }
}

