//
//  PTPanoramaGesture.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/26/20.
//

import UIKit
import SceneKit

public class PTPanoramaPanGestureManager {
    public let rotationNode: SCNNode

    public var allowsVerticalRotation = true
    public var minimumVerticalRotationAngle: Float?
    public var maximumVerticalRotationAngle: Float?

    public var allowsHorizontalRotation = true
    public var minimumHorizontalRotationAngle: Float?
    public var maximumHorizontalRotationAngle: Float?

    lazy var gestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = AdvancedPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        recognizer.earlyTouchEventHandler = { [weak self] in
            guard let self = self else { return }
            self.stopAnimations()
            self.resetReferenceAngles()
        }
        return recognizer
    }()

    private var referenceAngles: SCNVector3?

    init(rotationNode: SCNNode) {
        self.rotationNode = rotationNode
    }

    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        switch sender.state {
        case .changed:
            guard let referenceAngles = referenceAngles else { break }
            
            var angles = SCNVector3Zero
            let viewSize = max(view.bounds.width, view.bounds.height)
            let translation = sender.translation(in: view)

            if allowsVerticalRotation {
                var angle = referenceAngles.x + Float(translation.y / viewSize) * (.pi / 2)
                if let minimum = minimumVerticalRotationAngle {
                    angle = max(angle, minimum)
                }
                if let maximum = maximumVerticalRotationAngle {
                    angle = min(angle, maximum)
                }
                angles.x = angle
            }

            if allowsHorizontalRotation {
                var angle = referenceAngles.y + Float(translation.x / viewSize) * (.pi / 2)
                if let minimum = minimumHorizontalRotationAngle {
                    angle = max(angle, minimum)
                }
                if let maximum = maximumHorizontalRotationAngle {
                    angle = min(angle, maximum)
                }
                angles.y = angle
            }

            SCNTransaction.lock()
            SCNTransaction.begin()
            SCNTransaction.disableActions = true

            rotationNode.eulerAngles = angles.normalized

            SCNTransaction.commit()
            SCNTransaction.unlock()

        case .ended:
            var angles = rotationNode.eulerAngles
            let velocity = sender.velocity(in: view)
            let viewSize = max(view.bounds.width, view.bounds.height)

            if allowsVerticalRotation {
                var angle = angles.x
                angle += Float(velocity.y / viewSize) / .pi
                if let minimum = minimumVerticalRotationAngle {
                    angle = max(angle, minimum)
                }
                if let maximum = maximumVerticalRotationAngle {
                    angle = min(angle, maximum)
                }
                angles.x = angle
            }

            if allowsHorizontalRotation {
                var angle = angles.y
                angle += Float(velocity.x / viewSize) / .pi
                if let minimum = minimumHorizontalRotationAngle {
                    angle = max(angle, minimum)
                }
                if let maximum = maximumHorizontalRotationAngle {
                    angle = min(angle, maximum)
                }
                angles.y = angle
            }

            SCNTransaction.lock()
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1)
            
            rotationNode.eulerAngles = angles
            
            SCNTransaction.commit()
            SCNTransaction.unlock()

        default:
            break
        }
    }

    func stopAnimations() {
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.disableActions = true

        rotationNode.eulerAngles = rotationNode.presentation.eulerAngles.normalized
        rotationNode.removeAllAnimations()

        SCNTransaction.commit()
        SCNTransaction.unlock()
    }

    func resetReferenceAngles() {
        referenceAngles = rotationNode.presentation.eulerAngles
    }
}

final class AdvancedPanGestureRecognizer: UIPanGestureRecognizer {
    var earlyTouchEventHandler: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if state == .possible {
            earlyTouchEventHandler?()
        }
    }
}
