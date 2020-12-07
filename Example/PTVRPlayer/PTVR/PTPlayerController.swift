//
//  PTPlayerController.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

protocol PTPlayerControler: class {
    func close()
    func play()
    func pause()
    func togglePlayPause()
    func enterVRMode()
    func endVRMode()
    func seek(to: TimeInterval, completion: ((Bool) -> Void)?)
    func forward(second: TimeInterval)
    func backward(second: TimeInterval)
    func focus(_ animated: Bool)
}
