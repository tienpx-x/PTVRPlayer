//
//  VideoPlayerController.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import AVFoundation
import AVKit
import SceneKit
import PTVRPlayer
import SnapKit

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
    var playerViews: [PTControlView] = []
    var playerBag = DisposeBag()
    var playerItemBag = DisposeBag()
    var stereoView: PTStereoView?
    var timeObserver: Any?
    var vrControl: PTVRStereoControl?
    
    // Safe Area
    let topSafeArea = Util.getTopSafeAreaPadding()
    let botSafeArea = Util.getBottomSafeAreaPadding()
    
    var isInVRMode: Bool {
        return stereoView != nil
    }
    
    var isStartingVRMode = false
    
    var currentOrientation: UIDeviceOrientation = .portrait
    
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
        // Custom
        UIApplication.shared.delegate?.window??.tag = 99
        
        Util.disableDeviceGoSleep()
        
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
        
        playerViews = [portraitControlView, landscapeControlView]
        configure(player: player)
        
        UIDevice.current.rx.orientationChanged
            .startWith(UIDeviceOrientation.portrait)
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] (value) in
                self.handleOrientation(value)
            })
            .disposed(by: rx.disposeBag)
    }
    
    deinit {
        print(String(describing: type(of: self)) + " deinit")
        NotificationCenter.default.removeObserver(self)
        if timeObserver != nil {
            player?.removeTimeObserver(timeObserver!)
        }
    }
    
    // MARK: - Methods
    
    func addVideoPlayerController() {
        layoutControlView()
        panoramaView.addControl(view: portraitControlView)
        panoramaView.addControl(view: landscapeControlView)
    }
    
    func handleOrientation(_ value: UIDeviceOrientation) {
        guard !isStartingVRMode else { return }
        switch value {
        case .portrait, .portraitUpsideDown:
            self.currentOrientation = value
            print("portrait")
            self.setFOV(120)
            self.setLockRotation(45)
            self.portraitControlView.isHidden = false
            self.landscapeControlView.isHidden = true
        case .landscapeLeft, .landscapeRight:
            self.setFOV(90)
            self.setLockRotation(25)
            self.currentOrientation = value
            print("landscape")
            self.portraitControlView.isHidden = true
            self.landscapeControlView.isHidden = false
        default:
            print("unknown")
        }
        self.playerViews.forEach {
            $0.showControlView()
        }
        panoramaView.setNeedsResetRotation(animated: true)
    }
    
    func setFOV(_ fov: CGFloat) {
        let node = panoramaView.leftOrientationNode
        node.fieldOfView = fov
    }
    
    func setLockRotation(_ lockDegree: Float) {
        let rad = lockDegree * .pi / 180
        let manager = panoramaView.panGestureManager
        manager.minimumVerticalRotationAngle = -rad
        manager.maximumVerticalRotationAngle = rad
        manager.minimumHorizontalRotationAngle = -rad
        manager.maximumHorizontalRotationAngle = rad
    }
    
    func layoutControlView() {
        let nativeBounds = UIScreen.main.nativeBounds
        let screen = CGSize(width: nativeBounds.width / UIScreen.main.nativeScale, height: (nativeBounds.height / UIScreen.main.nativeScale) - topSafeArea - botSafeArea)
        portraitControlView.frame = CGRect(origin: .zero, size: screen)
        landscapeControlView.frame = CGRect(x: 0, y: 0, width: screen.height, height: screen.width)
        portraitControlView.layoutIfNeeded()
        landscapeControlView.layoutIfNeeded()
        panoramaView.layoutIfNeeded()
    }
    
    func configure(player: PTPlayer?) {
        guard let player = player else { return }
        addVideoPlayerController()
        
        panoramaView.addControl(view: portraitControlView)
        panoramaView.addControl(view: landscapeControlView)
        
        panoramaView.load(player: player, format: .stereoSBS)
        
        tracking(player: player)
        
        // set initial process & duration value for control view
        playerViews.forEach {
            $0.duration = player.duration
            $0.process = player.currentTime().seconds
        }
        
        play()
        
        panoramaView.setNeedsResetRotation(animated: false)
        setPanoramaMode()
    }
    
    func tracking(player: PTPlayer) {
        playerBag = DisposeBag()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 33, timescale: 1000),
                                                      queue: nil) { [weak self] (time) in
                                                        self?.playerViews.forEach {
                                                            $0.duration = self?.player?.duration ?? 0
                                                            $0.process = time.seconds
                                                            DispatchQueue.main.async {
                                                                self?.vrControl?.progressSlider.maximumValue = Float(self?.player?.duration ?? 0)
                                                                self?.vrControl?.progressNode.type = .slider(self?.player?.duration ?? 0)
                                                                self?.vrControl?.progressSlider.value = Float(time.seconds)
                                                                self?.vrControl?.leftTimeLabel.second = time.seconds
                                                                self?.vrControl?.rightTimeLabel.second = self?.player?.duration ?? 0
                                                            }
                                                        }
                                                        
        }
        player.rx.observe(Bool.self, #keyPath(PTPlayer.isPlaying))
            .observeOn(MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] (value) in
                self?.playerViews.forEach {
                    $0.isPlaying = value
                }
                DispatchQueue.main.async {
                    let playImage = UIImage(named: "ic_vr_play")
                    let pauseImage =  UIImage(named: "ic_vr_pause")
                    self?.vrControl?.playButton.setImage(value ? pauseImage : playImage, for: .normal)
                }
            })
            .disposed(by: playerBag)
        
        player.rx.observe(Float.self, #keyPath(PTPlayer.rate))
            .observeOn(MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (rate) in
                guard let player = self.player, let duration = player.currentItem?.duration, rate == 0 else {
                    return
                }
                let isVideoEnded = CMTimeCompare(player.currentTime(), duration) > -1
                if isVideoEnded {
                    self.playerItemDidPlayToEndTime()
                } else {
                    self.playerItemDidNotPlayToEndTime()
                }
            })
            .disposed(by: playerBag)
        
        player.rx.observe(AVPlayerItem.self, #keyPath(AVPlayer.currentItem))
            .subscribe(onNext: { [unowned self] (item) in
                guard let item = item else {
                    self.playerItemBag = DisposeBag()
                    return
                }
                self.addObserver(playerItem: item)
            })
            .disposed(by: playerBag)
    }
    
    func playerItemDidPlayToEndTime() {
        if isInVRMode {
            endVRMode()
        }
        playerViews.forEach {
            $0.isEnded = true
        }
        Util.enableDeviceGoSleep()
    }
    
    func playerItemDidNotPlayToEndTime() {}
    
    func addResetGesture() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(setNeedsResetRotation(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc func setNeedsResetRotation(_ sender: Any?) {
        panoramaView.setNeedsResetRotation(animated: true)
    }
}

// MARK: - AVPlayerItem
extension PTPlayerViewController {
    func addObserver(playerItem: AVPlayerItem) {
        playerItemBag = DisposeBag()
        if playerItem.status != .readyToPlay {
            playerViews.forEach {
                $0.isLoading = true
            }
        }
        playerItem.rx.observe(AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                switch value {
                case .readyToPlay:
                    self.playerViews.forEach {
                        $0.isLoading = false
                        $0.duration = self.player?.duration ?? 0
                    }
                    break
                case .failed:
                    guard let error = playerItem.error else { break }
                    self.handleMediaError(error)
                    break
                case .unknown:
                    break
                default:
                    break
                }
            })
            .disposed(by: playerItemBag)
        
        playerItem.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                self.playerViews.forEach {
                    $0.isLoading = value
                }
            })
            .disposed(by: playerItemBag)
        
        playerItem.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferFull))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                if value == true {
                    self.playerViews.forEach {
                        $0.isLoading = false
                    }
                }
            })
            .disposed(by: playerItemBag)
        
        playerItem.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                if value == true {
                    self.playerViews.forEach {
                        $0.isLoading = false
                    }
                }
            })
            .disposed(by: playerItemBag)
    }
}

extension PTPlayerViewController: PTPlayerControler {
    func close() {
        // Custom
        UIApplication.shared.delegate?.window??.tag = 0
        setPortrait()
        Util.disableDeviceGoSleep()
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
    
    func seek(to: TimeInterval, completion: ((Bool) -> Void)?) {
        guard let player = player else {
            completion?(false)
            return
        }
        playerViews.forEach {
            $0.isSeeking = true
        }
        player.seek(to: to) { [weak self] (isSuccess) in
            guard let self = self else { return }
            self.playerViews.forEach {
                $0.isSeeking = false
                $0.process = player.currentTime().seconds
            }
            player.play()
            completion?(isSuccess)
        }
    }
    
    func focus(_ animated: Bool) {
        DispatchQueue.main.async {
            self.panoramaView.setNeedsResetRotation(animated: animated)
        }
    }
    
    func forward(second: TimeInterval) {
        guard let player = player else { return }
        let currentTime = player.currentTime().seconds
        let forwardTime = currentTime + second
        seek(to: forwardTime, completion: nil)
    }
    
    func backward(second: TimeInterval) {
        guard let player = player else { return }
        let currentTime = player.currentTime().seconds
        let backwardTime = currentTime - second
        seek(to: backwardTime, completion: nil)
    }
    
    func enterVRMode() {
        isStartingVRMode = true
        // Custom
        UIApplication.shared.delegate?.window??.tag = 999
        setLandscape()
        let vc = UIViewController();
        PTStereoView(device: self.panoramaView.device).do {
            // Controller
            let vrControl = PTVRStereoControl()
            vrControl.controller = self
            self.vrControl = vrControl
            $0.renderController.append(vrControl.opacityNode)
            $0.renderController.append(vrControl.playerNode)
            //
            $0.scene = self.panoramaView.scene
            $0.frame = vc.view.frame
            self.vrControlView.frame = vc.view.frame
            vc.view.addSubview($0)
            vc.view.insertSubview(self.vrControlView, aboveSubview: $0)
            self.stereoView = $0
        }
        self.navigationController?.pushViewController(vc, animated: false)
        setStereoMode()
        panoramaView.isHidden = true
        isStartingVRMode = false
    }
    
    func endVRMode() {
        // Custom
        setPanoramaMode()
        UIApplication.shared.delegate?.window??.tag = 99
        navigationController?.popViewController(animated: false)
        stereoView?.removeFromSuperview()
        panoramaView.isHidden = false
        self.stereoView = nil
        self.handleOrientation(UIDeviceOrientation.landscapeRight)
    }
}

// MARK: - Error
extension PTPlayerViewController {
    func handleMediaError(_ error: Error) {
        print("Error: \(error)")
        var message = ""
        let error = error as NSError
        switch error.code {
        case -11800: // The operation could not be completed
            message = "操作を完了できませんでした"
        default:
            message = error.localizedDescription
        }
        //        self.showAlert(message: message, completion: {
        //            self.dismiss(animated: true, completion: nil)
        //        })
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Rotation
extension PTPlayerViewController {
    func setLandscape() {
        // Force to landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
        layoutControlView()
    }
    
    func setPortrait() {
        // Force to portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
        layoutControlView()
    }
}

// MARK: - Center
extension PTPlayerViewController {
    func setPanoramaMode() {
        panoramaView.leftOrientationNode.fullResetRotation()
        panoramaView.rightOrientationNode.fullResetRotation()
        panoramaView.scene?.leftOrientationNode.fullResetRotation()
        panoramaView.scene?.rightOrientationNode.fullResetRotation()
        panoramaView.scene?.leftMediaNode.eulerAngles = SCNVector3Make(0, Util.deg2rad(-90), 0)
        panoramaView.scene?.rightMediaNode.eulerAngles = SCNVector3Make(0, Util.deg2rad(-90), 0)
    }
    
    func setStereoMode() {
        panoramaView.leftOrientationNode.fullResetRotation()
        panoramaView.rightOrientationNode.fullResetRotation()
        panoramaView.scene?.leftOrientationNode.fullResetRotation()
        panoramaView.scene?.rightOrientationNode.fullResetRotation()
        panoramaView.scene?.leftMediaNode.eulerAngles = SCNVector3Make(0, Util.deg2rad(-180), 0)
        panoramaView.scene?.rightMediaNode.eulerAngles = SCNVector3Make(0, Util.deg2rad(-180), 0)
    }
}


// MARK: - StoryboardSceneBased
extension PTPlayerViewController: StoryboardSceneBased {
    static let sceneStoryboard = UIStoryboard(name: "PTPlayerView", bundle: nil)
}
