//
//  PTPlayerController.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//
import PTVRPlayer

protocol PTPlayerControler: UIViewController {
    func close()
    func play()
    func pause()
    func togglePlayPause()
    func enterVRMode()
    func endVRMode()
    func seek(to: TimeInterval, completion: ((Bool) -> Void)?)
    func forward(second: TimeInterval)
    func backward(second: TimeInterval)
    func stepForward()
    func stepBackward()
    func focus(_ animated: Bool)
    func changeModel(_ model: ViewerParametersProtocol)
}
