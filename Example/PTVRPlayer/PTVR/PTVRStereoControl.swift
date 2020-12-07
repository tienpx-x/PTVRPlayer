//
//  PTVRStereoControl.swift
//  PTVRPlayer_Example
//
//  Created by Phạm Xuân Tiến on 12/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SceneKit
import PTVRPlayer

class PTVRStereoControl {
    
    let tWidth = 150
    let tHeight = 40
    let startP: Float = -0.9
    let sWidth: CGFloat = 0.45
    let sHeight: CGFloat = 0.08
    let up: Float = -0.2
    let rotateX: Float = Util.deg2rad(45)
    let rotateY: Float = Util.deg2rad(-90)
    let rotateZ: Float = Util.deg2rad(0)
    
    // Action
    
    var controller: PTPlayerViewController?
    
    // UI
    
    lazy var titleLabel: UILabel = {
        return UILabel(frame: CGRect(x: 0, y: 0, width: tWidth, height: 20)).then {
            $0.isOpaque = false
            $0.text = "Amet minim mollit non dese asdsadsadsadasdasdasds sad asd sad sa asdsadads"
            $0.textColor = .white
            $0.adjustsFontSizeToFitWidth = false
            $0.lineBreakMode = .byTruncatingTail
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 8)
        }
    }()
    
    lazy var progressSlider: PTUISlider = {
        return PTUISlider(frame: CGRect(x: 0, y: 0, width: tWidth, height: tHeight / 2)).then {
            $0.isOpaque = false
            $0.setThumbImage(UIImage(), for: .normal)
            $0.tintColor = UIColor.clear
            $0.maximumTrackTintColor = #colorLiteral(red: 0.7803921569, green: 0.7921568627, blue: 0.8196078431, alpha: 1)
            $0.value = 40
            $0.minimumValue = 0
            $0.maximumValue = 100
        }
    }()
    
    lazy var leftTimeLabel: TimeLabel = {
        return TimeLabel(frame: CGRect(x: 0, y: 0, width: tWidth / 2, height: tHeight)).then {
            $0.isOpaque = false
            $0.textColor = .white
            $0.textAlignment = .left
            $0.font = UIFont.systemFont(ofSize: 8)
        }
    }()
    
    lazy var rightTimeLabel: TimeLabel = {
        return TimeLabel(frame: CGRect(x: tWidth / 2, y: 0, width: tWidth / 2, height: tHeight)).then {
            $0.isOpaque = false
            $0.textColor = .white
            $0.textAlignment = .right
            $0.font = UIFont.systemFont(ofSize: 8)
        }
    }()
    
    lazy var timeView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: tWidth, height: tHeight)).then {
            $0.isOpaque = false
            $0.addSubview(leftTimeLabel)
            $0.addSubview(rightTimeLabel)
        }
    }()
    
    let buttonColor: UIColor = #colorLiteral(red: 0.1803921569, green: 0.1921568627, blue: 0.2196078431, alpha: 0.8)
    let selectedColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    
    lazy var playButton: UIButton = {
        return UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40)).then {
            $0.layer.cornerRadius = 40 / 2
            $0.layer.borderWidth = 0
            $0.layer.borderColor = UIColor.clear.cgColor
            $0.layer.masksToBounds = true
            $0.backgroundColor = buttonColor
            $0.setImage(UIImage(named: "ic_vr_pause"), for: .normal)
        }
    }()
    
    lazy var next30Button: UIButton = {
        return UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40)).then {
            $0.layer.cornerRadius = 40 / 2
            $0.layer.borderWidth = 0
            $0.layer.borderColor = UIColor.clear.cgColor
            $0.layer.masksToBounds = true
            $0.backgroundColor = buttonColor
            $0.setImage(#imageLiteral(resourceName: "ic_next30"), for: .normal)
        }
    }()
    
    lazy var prev30Button: UIButton = {
        return UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40)).then {
            $0.layer.cornerRadius = 40 / 2
            $0.layer.borderWidth = 0
            $0.layer.borderColor = UIColor.clear.cgColor
            $0.layer.masksToBounds = true
            $0.backgroundColor = buttonColor
            $0.setImage(#imageLiteral(resourceName: "ic_prev30"), for: .normal)
        }
    }()
    
    // Nodes
    
    lazy var opacityNode: PTRenderObject = {
        let node = PTRenderObject(geometry: SCNSphere(radius: 9.99).then {
            $0.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
            $0.segmentCount = 96
            $0.firstMaterial?.cullMode = .front
        })
        node.scale = SCNVector3(x: 1, y: 1, z: -1)
        node.name = "Base Object"
        return node
    }()
    
    lazy var playerNode: PTRenderObject = {
        let node = PTRenderObject(geometry: SCNPlane(width: sWidth, height: 1).with {
            $0.firstMaterial?.diffuse.contents = UIColor.clear
            $0.firstMaterial?.cullMode = .front
        })
        node.eulerAngles.x = rotateX
        node.eulerAngles.y = rotateY
        node.eulerAngles.z = rotateZ
        node.addChildNode(titleNode)
        node.addChildNode(playButtonNode)
        node.addChildNode(progressNode)
        node.addChildNode(timeNode)
        node.addChildNode(next30Node)
        node.addChildNode(back30Node)
//        node.addChildNode(hideNode)
        node.name = "Base Object"
        node.position = SCNVector3Make(startP, up, 0)
        return node
    }()
    
    
    lazy var titleNode: PTRenderObject = {
        return PTRenderObject(geometry: SCNPlane(width: sWidth, height: 0.08).then {
            $0.firstMaterial?.diffuse.contents = titleLabel
            $0.firstMaterial?.cullMode = .front
        }).then {
            $0.name = "Title Node"
            $0.position = SCNVector3Zero
        }
    }()
    
    lazy var playButtonNode: PTRenderObject = {
        let plane = SCNPlane(width: 0.08, height: 0.08).then {
            $0.firstMaterial?.diffuse.contents = playButton
            $0.firstMaterial?.cullMode = .front
        }
        let object = PTRenderObject(geometry: plane).then {
            $0.name = "Play Button"
            $0.canFocused = true
            $0.action = { [weak self] _ in
                guard let self = self else { return }
                self.controller?.togglePlayPause()
            }
            $0.focusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.1
                plane.height = 0.1
                self.playButton.backgroundColor = self.selectedColor
            }
            $0.unFocusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.08
                plane.height = 0.08
                self.playButton.backgroundColor = self.buttonColor
            }
            $0.position = SCNVector3Make(0, -0.1 , 0)
        }
        return object
    }()
    
    lazy var next30Node: PTRenderObject = {
        let plane = SCNPlane(width: 0.06, height: 0.06).then {
            $0.firstMaterial?.diffuse.contents = next30Button
            $0.firstMaterial?.cullMode = .front
        }
        let object = PTRenderObject(geometry: plane).then {
            $0.name = "Next Button"
            $0.canFocused = true
            $0.action = { [weak self] _ in
                guard let self = self else { return }
                self.controller?.forward(second: 30)
            }
            $0.focusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.08
                plane.height = 0.08
                self.next30Button.backgroundColor = self.selectedColor
            }
            $0.unFocusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.06
                plane.height = 0.06
                self.next30Button.backgroundColor = self.buttonColor
            }
            $0.position = SCNVector3Make(0.12, -0.1 , 0)
        }
        return object
    }()
    
    lazy var back30Node: PTRenderObject = {
        let plane = SCNPlane(width: 0.06, height: 0.06).then {
            $0.firstMaterial?.diffuse.contents = prev30Button
            $0.firstMaterial?.cullMode = .front
        }
        let object = PTRenderObject(geometry: plane).then {
            $0.name = "Back Button"
            $0.canFocused = true
            $0.action = { [weak self] _ in
                guard let self = self else { return }
                self.controller?.backward(second: 30)
            }
            $0.focusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.08
                plane.height = 0.08
                self.prev30Button.backgroundColor = self.selectedColor
            }
            $0.unFocusAction = { [weak self] in
                guard let self = self else { return }
                plane.width = 0.06
                plane.height = 0.06
                self.prev30Button.backgroundColor = self.buttonColor
            }
            $0.position = SCNVector3Make(-0.12, -0.1 , 0)
        }
        return object
    }()
    
    lazy var progressNode: PTRenderObject = {
        return PTRenderObject(geometry: SCNPlane(width: sWidth, height: 0.02).then {
            $0.firstMaterial?.diffuse.contents = progressSlider
            $0.firstMaterial?.cullMode = .front
        }).then {
            $0.name = "Progress Node"
            $0.canFocused = true
            $0.type = .slider(0)
            $0.action = { time in
                guard let time = time as? TimeInterval else { return }
                self.controller?.seek(to: time, completion: nil)
            }
            $0.position = SCNVector3Make(0, -0.2 , 0)
        }
    }()
    
    lazy var timeNode: PTRenderObject = {
        return PTRenderObject(geometry: SCNPlane(width: sWidth, height: 0.1).then {
            $0.firstMaterial?.diffuse.contents = timeView
            $0.firstMaterial?.cullMode = .front
        }).then {
            $0.name = "Time Node"
            $0.position = SCNVector3Make(0, -0.260 , 0)
        }
    }()
    
    lazy var hideNode: PTRenderObject = {
        return PTRenderObject(geometry: SCNPlane(width: 0.03, height: 0.03).then {
            $0.firstMaterial?.diffuse.contents = UIColor.red
            $0.firstMaterial?.cullMode = .front
        }).then {
            $0.name = "Hide Node"
            $0.position = SCNVector3Make(0, -0.260 , 0)
            $0.canFocused = true
            $0.action = { _ in
                self.controller?.stereoView?.hideController()
            }
        }
    }()
}
