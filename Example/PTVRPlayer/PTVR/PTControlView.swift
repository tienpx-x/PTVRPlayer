//
//  PTControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

protocol PTControlView: UIView {
    var playerController: PTPlayerControler? { get set }
    var isPlaying: Bool { get set }
    var isLoading: Bool { get set }
    var isSeeking: Bool { get set }
    var isEnded: Bool { get set }
    var duration: TimeInterval { get set }
    var process: TimeInterval { get set }
    var canStepFoward: Bool { get set }
    var canStepBackward: Bool { get set }
    func showControlView()
    func hideControlView()
}
