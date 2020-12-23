//
//  PTPTOrientationNode.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import SceneKit
import CoreMotion

public protocol PTOrientationDelegate: class {
    func didInRangeHorizontal(orientationNode: PTOrientationNode)
    func didMaxLeftHorizontal(orientationNode: PTOrientationNode)
    func didMaxRightHorizontal(orientationNode: PTOrientationNode)
    func didInRangeVertical(orientationNode: PTOrientationNode)
    func didMaxTopVertical(orientationNode: PTOrientationNode)
    func didMaxBottomVertical(orientationNode: PTOrientationNode)
}

public class PTOrientationNode: SCNNode {
    
    public weak var delegate: PTOrientationDelegate?
    
    public var maximumVerticalRotationAngle: Float?
    public var maximumHorizontalRotationAngle: Float?
    public var allowsUserRotation = false
    
    let userRotationNode = SCNNode()
    let referenceRotationNode = SCNNode()
    let deviceOrientationNode = SCNNode()
    let interfaceOrientationNode = SCNNode()
    
    public var cursorNode: SCNNode = {
        let plane = SCNCylinder(radius: 0.01, height: 0.2)
        plane.firstMaterial?.isDoubleSided = true
        return SCNNode(geometry: plane).then {
            $0.name = "Cursor Node"
            $0.eulerAngles.x = deg2rad(80)
            $0.eulerAngles.y = deg2rad(-2)
            $0.position = SCNVector3Make(0, 0.1, -0.9)
        }
    }()
    
    public let pointOfView = SCNNode()
    
    public var fieldOfView: CGFloat = 90 {
        didSet {
            self.updateCamera()
        }
    }
    
    public var deviceOrientationProvider: DeviceOrientationProvider? = DefaultDeviceOrientationProvider()
    
    public var interfaceOrientationProvider: InterfaceOrientationProvider? = DefaultInterfaceOrientationProvider()
    
    // Lock
    var rHoz: Double = 45
    var lHoz: Double = -45
    var hozPlus: Double = 45

    var tVer: Double = -40
    var bVer: Double = -120
    var rootHoz: Float = -180
    var radiusHoz: Double = 90
    
    var previousYaw: Double = 0
    var correctYaw: Double = 0
    var multipleYaw: Double = 1
    
    private var initAttitude: CMAttitude?
    
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
        
        pointOfView.addChildNode(cursorNode)
        cursorNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        cursorNode.isHidden = true
        
        let camera = SCNCamera()
        camera.zNear = 0.3
        pointOfView.camera = camera
        
        updateCamera()
    }
    
    public func setCursorView(view: UIView) {
        let m1 = SCNMaterial()
        m1.diffuse.contents = UIColor.clear
        let m2 = SCNMaterial()
        m2.diffuse.contents = view
        cursorNode.geometry?.materials = [m1 , m2]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateDeviceOrientation(scene: PTStereoScene? = nil,
                                        atTime time: TimeInterval = ProcessInfo.processInfo.systemUptime,
                                        node: SCNNode? = nil,
                                        forEye eye: Eye = .left) {
        guard let deviceRotation = deviceOrientationProvider?.deviceOrientation(atTime: time) else {
            return
        }
        if allowsUserRotation {
            
        } else {
            var rotation = deviceRotation.rotation
            
            let x = rad2deg(deviceRotation.attitude.roll)
            let y = rad2deg(deviceRotation.attitude.yaw)
            let z = rad2deg(deviceRotation.attitude.pitch)
            // In [0,360]
            let _ = (y + 450).truncatingRemainder(dividingBy: 360)
            if let _ = initAttitude {
            } else {
                initAttitude = deviceRotation.attitude
            }
            if let node = node {
                var currentYaw = (y + correctYaw) * multipleYaw
                // Rotate
                if(z < 60 && z > -60) {
                    
                } else {
                    return
                }
                
                // Direction
                if(self.previousYaw < -170 && y > 170) {
                    deviceOrientationProvider?.reset()
                    currentYaw = 0
                    initAttitude = nil
                    lHoz = 0
                    rHoz = 45
                    return
                } else if(self.previousYaw > 170 && y < 0) {
                    deviceOrientationProvider?.reset()
                    currentYaw = 0
                    initAttitude = nil
                    lHoz = -45
                    rHoz = 0
                    return
                }

                // Horizontal
                if(currentYaw > rHoz) {
                    let rad = deg2rad(rootHoz) + Float(deg2rad(currentYaw - hozPlus))
                    node.eulerAngles.y = rad
                    lHoz = currentYaw - radiusHoz
                    rHoz = currentYaw
                    delegate?.didMaxRightHorizontal(orientationNode: self)
                } else if (currentYaw < lHoz) {
                    let rad = deg2rad(rootHoz) + Float(deg2rad(currentYaw + hozPlus))
                    node.eulerAngles.y = rad
                    rHoz = currentYaw + radiusHoz
                    lHoz = currentYaw
                    delegate?.didMaxLeftHorizontal(orientationNode: self)
                } else {
                    delegate?.didInRangeHorizontal(orientationNode: self)
                }
                
                // Vertical
                if(x > self.tVer) {
                    rotation.rotate(byY: Float(deg2rad(self.tVer - x)))
                    delegate?.didMaxBottomVertical(orientationNode: self)
                } else if (x < self.bVer) {
                    rotation.rotate(byY: Float(deg2rad(self.bVer - x)))
                    delegate?.didMaxTopVertical(orientationNode: self)
                } else {
                    delegate?.didInRangeVertical(orientationNode: self)
                }
            }
            print("[LOG-PARAM] \(y) - L: \(lHoz) R: \(rHoz)")
            self.previousYaw = y
            self.deviceOrientationNode.orientation = rotation.scnQuaternion
        }
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
    
    public func fullResetRotation() {
        eulerAngles = SCNVector3Zero
        userRotationNode.eulerAngles = SCNVector3Zero
        referenceRotationNode.eulerAngles = SCNVector3Zero
        deviceOrientationNode.eulerAngles = SCNVector3Zero
        interfaceOrientationNode.eulerAngles = SCNVector3Zero
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

