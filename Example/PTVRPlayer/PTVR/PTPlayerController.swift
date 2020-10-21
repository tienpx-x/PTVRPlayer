//
//  PTPlayerController.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

protocol PTPlayerControler: class {
    func close()
    func play()
    func pause()
    func togglePlayPause()
    func enterVRMode()
    func endVRMode()
}
