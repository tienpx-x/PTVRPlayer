//
//  VideoPlayerController.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import AVFoundation
import AVKit
import PTVRPlayer

enum ViewOrientation {
    case unknown
    case portrait
    case landscape
}

final class PTPlayerViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet weak var panoramaView: PTPanoramaView!
    var portraitControlView =  PTPortraitControlView()
    var landscapeControlView = PTLandscapeControlView()
    let vrControlView = PTVRControlView()
    
    // MARK: - Properties
    
    var player: PTPlayer?
    var playerView: PTControlView?
    var playerBag = DisposeBag()
    var stereoView: StereoView?
    var timeObserver: Any?
    
//    var isInVRMode: Bool {
//        return stereoView != nil
//    }
    
    // MARK: - Life Cycle
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        portraitControlView.do {
            $0.isHidden = true
            $0.playerController = self
        }
        landscapeControlView.do {
            $0.isHidden = true
            $0.playerController = self
        }
        vrControlView.do {
            $0.playerController = self
        }
        
        addResetGesture()
        
        playerView = portraitControlView
        configure(player: player)
        
        UIDevice.current.rx.orientationChanged
            .startWith(UIDeviceOrientation.portrait)
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] (value) in
                switch value {
                case .portrait, .portraitUpsideDown:
                    print("portrait")
                    self.portraitControlView.isHidden = false
                    self.landscapeControlView.isHidden = true
                case .landscapeLeft, .landscapeRight:
                    print("landscape")
                    self.portraitControlView.isHidden = true
                    self.landscapeControlView.isHidden = false
                default:
                    print("unknown")
                    self.portraitControlView.isHidden = false
                    self.landscapeControlView.isHidden = true
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if timeObserver != nil {
            player?.removeTimeObserver(timeObserver!)
        }
    }
    
    // MARK: - Methods
    
    func configure(player: PTPlayer?) {
        guard let player = player else { return }
        
        portraitControlView.frame = view.bounds
        landscapeControlView.frame = view.bounds
        
        panoramaView.addControl(view: portraitControlView)
        panoramaView.addControl(view: landscapeControlView)
        
        panoramaView.load(player: player, format: .stereoSBS)
        
        tracking(player: player)
        
        // set initial process & duration value for control view
        playerView?.duration = player.duration
        playerView?.process = player.currentTime().seconds
        
        player.seek(to: CMTime(seconds: 6, preferredTimescale: 1000))
        player.play()
//        panoramaView.setNeedsResetRotation(animated: false)
    }
    
    func tracking(player: PTPlayer) {
        playerBag = DisposeBag()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 33, timescale: 1000),
                                                       queue: nil) { [weak self] (time) in
                                                        self?.playerView?.duration = self?.player?.duration ?? 0
                                                        self?.playerView?.process = time.seconds
        }
        player.rx.observe(Bool.self, #keyPath(PTPlayer.isPlaying))
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] (value) in
                guard let self = self, let playerView = self.playerView else { return }
                playerView.isPlaying = value
            })
            .disposed(by: playerBag)
    }
    
    func addResetGesture() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(setNeedsResetRotation(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc func setNeedsResetRotation(_ sender: Any?) {
        panoramaView.setNeedsResetRotation(animated: true)
    }
}

extension PTPlayerViewController: PTPlayerControler {
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        player.isPlaying ? pause() : play()
    }
    
    func play() {
        guard let player = player else { return }
        // Set category before play video to enable sound when in silent mode
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        player.play()
    }
    
    func pause() {
        guard let player = player else { return }
        player.pause()
    }
    
    func enterVRMode() {
        // Force to landscape
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        let vc = UIViewController();
        StereoView(device: panoramaView.device).do {
            $0.scene = panoramaView.scene
            $0.frame = vc.view.frame
            vrControlView.frame = vc.view.frame
            vc.view.addSubview($0)
            vc.view.insertSubview(vrControlView, aboveSubview: $0)
//            self.stereoView = $0
            panoramaView.scene?.delegate = $0.stereoScene
            panoramaView.setStereoMode()
            $0.leftOrientationNode = panoramaView.leftOrientationNode
            $0.rightOrientationNode = panoramaView.rightOrientationNode
            panoramaView.isHidden = true
        }
        navigationController?.pushViewController(vc, animated: false)
    }
    
    func endVRMode() {
        panoramaView.setPanoMode()
        // Force to portrait
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        navigationController?.popViewController(animated: false)
        stereoView?.removeFromSuperview()
        panoramaView.isHidden = false
//        self.stereoView = nil
    }
}

// MARK: - StoryboardSceneBased
extension PTPlayerViewController: StoryboardSceneBased {
    static let sceneStoryboard = UIStoryboard(name: "PTPlayerView", bundle: nil)
}
