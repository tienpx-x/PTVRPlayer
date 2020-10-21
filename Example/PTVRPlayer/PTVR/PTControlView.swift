//
//  PTControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

protocol PTControlView: UIView {
    var playerController: PTPlayerControler? { get set }
    var isPlaying: Bool { get set }
    var isLoading: Bool { get set }
    var duration: TimeInterval { get set }
    var process: TimeInterval { get set }
}
