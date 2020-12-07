//
//  PTDeviceOrientation.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import CoreMotion

public struct DeviceRotation {
    let rotation: Rotation
    let attitude: CMAttitude
}

public protocol DeviceOrientationProvider {
    func deviceOrientation(atTime time: TimeInterval) -> DeviceRotation?
    func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool
    func getAccelertion() -> UIInterfaceOrientation
    func reset()
}

extension DeviceOrientationProvider {
    public func waitDeviceOrientation(atTime time: TimeInterval) {
        let _ = waitDeviceOrientation(atTime: time, timeout: .distantFuture)
    }
    
    public func waitDeviceOrientation(atTime time: TimeInterval, timeout: DispatchTime) -> DispatchTimeoutResult {
        guard deviceOrientation(atTime: time) == nil else {
            return .success
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let queue = DispatchQueue(label: "PTVRPlayer.DeviceOrientationProvider.waitingQueue")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(10))
        timer.setEventHandler {
            guard let _ = self.deviceOrientation(atTime: time) else {
                return
            }
            semaphore.signal()
        }
        timer.resume()
        defer { timer.cancel() }
        
        return semaphore.wait(timeout: timeout)
    }
}

extension CMMotionManager: DeviceOrientationProvider {
    public func reset() {
        stopDeviceMotionUpdates()
        deviceMotionUpdateInterval = 1 / 60
        startDeviceMotionUpdates()
    }
    
    public func getAccelertion() -> UIInterfaceOrientation {
        guard let acceleration = accelerometerData?.acceleration else {  return .unknown }
        if acceleration.x >= 0.75 {
            return .landscapeLeft
        }
        else if acceleration.x <= -0.75 {
            return .landscapeRight
        }
        else if acceleration.y <= -0.75 {
            return .portrait
            
        }
        else if acceleration.y >= 0.75 {
            return .portraitUpsideDown
        }
        else {
            return .unknown
        }
    }
    
    public func deviceOrientation(atTime time: TimeInterval) -> DeviceRotation? {
        guard let motion = deviceMotion else {
            return nil
        }
        
        let timeInterval = time - motion.timestamp
        
        guard timeInterval < 1 else {
            return nil
        }
        
        var rotation = Rotation(motion)
        
        if timeInterval > 0 {
            let rx = motion.rotationRate.x * timeInterval
            let ry = motion.rotationRate.y * timeInterval
            let rz = motion.rotationRate.z * timeInterval
            
            rotation.rotate(byX: Float(rx))
            rotation.rotate(byY: Float(ry))
            rotation.rotate(byZ: Float(rz))
        }
        
        let reference = Rotation(x: .pi / 2)
        
        return DeviceRotation(rotation: reference.inverted() * rotation.normalized(), attitude: motion.attitude)
    }
    
    public func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return isDeviceMotionActive && time - (deviceMotion?.timestamp ?? 0) > 1
    }
}

internal final class DefaultDeviceOrientationProvider: DeviceOrientationProvider {
    let motionManager = CMMotionManager()

    init() {
        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func deviceOrientation(atTime time: TimeInterval) -> DeviceRotation? {
        return motionManager.deviceOrientation(atTime: time)
    }
    
    func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return motionManager.shouldWaitDeviceOrientation(atTime: time)
    }
    
    func getAccelertion() -> UIInterfaceOrientation {
        return motionManager.getAccelertion()
    }
    
    func reset() {
        return motionManager.reset()
    }
}

