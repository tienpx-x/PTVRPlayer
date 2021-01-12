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
import RxAppState

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
    var playerStartTime: TimeInterval?
    var retryTimer: Timer?
    var videos: ListVideo?
    var currentIndex = 0
    var currentVideo: Video? {
        guard let videos = videos, videos.items.count > currentIndex else { return nil }
        return videos.items[currentIndex]
    }
    
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
        
        configPanorama()
        
        configure(player: player)
        
        UIDevice.current.rx.orientationChanged
            .startWith(UIDeviceOrientation.portrait)
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] (value) in
                self.handleOrientation(value)
            })
            .disposed(by: rx.disposeBag)
        
        UIApplication.shared.rx.applicationWillEnterForeground
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {  [unowned self] _ in
                panoramaView.scene?.isPaused = false
                panoramaView.startRender()
                //                if let stereoView = stereoView {
                //                    let vrControl = PTVRStereoControl()
                //                    vrControl.controller = self
                //                    self.vrControl = vrControl
                //                    stereoView.removeControllerObject()
                //                    stereoView.renderController.append(vrControl.opacityNode)
                //                    stereoView.renderController.append(vrControl.playerNode)
                //                    stereoView.resetController()
                //                }
            })
            .disposed(by: rx.disposeBag)
        
        UIApplication.shared.rx.applicationDidEnterBackground
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {  [unowned self] _ in
                panoramaView.scene?.isPaused = true
                panoramaView.stopRender()
                self.endVRMode()
            })
            .disposed(by: rx.disposeBag)
    }
    
    deinit {
        print(String(describing: type(of: self)) + " deinit")
        NotificationCenter.default.removeObserver(self)
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
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
    
    func configPanorama() {
        panoramaView.backgroundColor = .black
        addVideoPlayerController()
    }
    
    func configure(player: PTPlayer?) {
        guard let player = player else { return }
        configStepButton()
        
        panoramaView.load(player: player, format: .stereoSBS)
        
        //        panoramaView.scene?.leftMediaNode.addEffect(image: #imageLiteral(resourceName: "effect"))
        //        panoramaView.scene?.rightMediaNode.addEffect(image: #imageLiteral(resourceName: "effect"))
        
        tracking(player: player)
        player.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player.automaticallyWaitsToMinimizeStalling = true
        
        // set initial process & duration value for control view
        playerViews.forEach {
            $0.duration = player.duration
            $0.process = player.currentTime().seconds
        }
        setPanoramaMode()
        panoramaView.setNeedsResetRotation(animated: false)
        play()
    }
    
    func tracking(player: PTPlayer) {
        playerBag = DisposeBag()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 100, timescale: 1000),
                                                      queue: DispatchQueue.main) { [weak self] (time) in
            guard let self = self else { return }
            let duration = self.player?.duration ?? 1
            let availableDuration = self.player?.availableDuration ?? 1
            print("Current: \(time.seconds) - Loaded: \(String(describing: self.player?.availableDuration)) - Duration: \(String(describing: self.player?.duration))")
            self.playerViews.forEach {
                $0.duration = duration
                $0.availableDuration = availableDuration
                $0.process = time.seconds
                //                if time.seconds > 0 {
                //                    $0.isLoading = false
                //                }
            }
            guard let vrControl = self.vrControl else { return }
            DispatchQueue.main.async {
                vrControl.progressNode.type = .slider(duration)
                let progress = Float(time.seconds / duration)
                let loadedProgress = Float(availableDuration / duration) - progress
                vrControl.progressView.setProgress(section: 0, to: progress)
                vrControl.progressView.setProgress(section: 1, to: loadedProgress)
                vrControl.leftTimeLabel.second = time.seconds
                vrControl.rightTimeLabel.second = duration
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
                    let playImage = UIImage(named: "ic_vr_play")?.resize(width: 10)
                    let pauseImage =  UIImage(named: "ic_vr_pause")?.resize(width: 10)
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
                if let player = self.player {
                    self.panoramaView.scene?.bind(player)
                    player.play()
                }
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
            if let stereoView = stereoView {
                stereoView.isLoading = true
            }
        }
        playerItem.rx.observe(AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                switch value {
                case .readyToPlay:
                    print("[LOG] readyToPlay")
                    let duration = self.player?.duration ?? 0
                    self.playerViews.forEach {
                        // $0.isLoading = false
                        $0.duration = duration
                    }
                    if let playerStartTime = playerStartTime {
                        print("[LOG] Set init start time \(playerStartTime)")
                        self.seek(to: playerStartTime, completion: nil)
                        self.playerStartTime = nil
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
                if let stereoView = stereoView {
                    stereoView.isLoading = value
                }
                print("[LOG] isPlaybackBufferEmpty - \(value)")
                //                print("[LOG] Start retry")
                //                if value {
                //                    retryTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
                //                        print("[LOG] Hit retry")
                //                        if let currentTime = player?.currentTime().seconds {
                //                            self.seek(to: currentTime, completion: nil)
                //                            timer.invalidate()
                //                        }
                //                    }
                //                }
            })
            .disposed(by: playerItemBag)
        
        playerItem.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferFull))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                if value == true {
                    self.playerViews.forEach {
                        if $0.isLoading == true {
                            $0.isLoading = false
                        }
                    }
                    if let stereoView = stereoView {
                        if stereoView.isLoading == true {
                            stereoView.isLoading = false
                        }
                    }
                }
                print("[LOG] isPlaybackBufferFull - \(value)")
            })
            .disposed(by: playerItemBag)
        
        playerItem.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
            .compactMap { $0 }
            .subscribe(onNext: { [unowned self] (value) in
                if value == true {
                    self.playerViews.forEach {
                        if $0.isLoading == true {
                            $0.isLoading = false
                        }
                    }
                    if let stereoView = stereoView {
                        if stereoView.isLoading == true {
                            stereoView.isLoading = false
                        }
                    }
                    retryTimer?.invalidate()
                }
                print("[LOG] isPlaybackLikelyToKeepUp - \(value)")
            })
            .disposed(by: playerItemBag)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(itemDidStall(_:)),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: playerItem)
    }
    
    @objc func itemDidStall(_ notification: Notification) {
        print(notification)
        print("[LOG] AVPlayer got stalled stream url")
        if let player = player, let playerItem = player.currentItem {
            if(!playerItem.isPlaybackLikelyToKeepUp) {
                let currentTime = player.currentTime().seconds
                //                self.playerStartTime = currentTime + 5
                //                print("[LOG] AVPlayer got stalled and replace \(currentTime)")
                //                retryTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] timer in
                //                    print("[LOG] Hit retry")
                //                    if let url = player.getVideoUrl() {
                //                        self?.playNewUrl(url: url)
                //                    }
                //                    timer.invalidate()
                //                }
            }
        }
    }
}

extension PTPlayerViewController {
    func configStepButton() {
        guard let videos = videos?.items else { return }
        guard let currentVideo = currentVideo else { return }
        let next = videos.next(item: currentVideo)
        let prev = videos.prev(item: currentVideo)
        playerViews.forEach {
            $0.canStepFoward = next != nil
            $0.canStepBackward = prev != nil
        }
        if isInVRMode {
            vrControl?.titleLabel.text = currentVideo.title
            vrControl?.canStepFoward = next != nil
            vrControl?.canStepBackward = prev != nil
        }
    }
}

extension PTPlayerViewController: PTPlayerControler {
    func changeModel(_ model: ViewerParametersProtocol) {
        guard let stereoView = stereoView else { return }
        stereoView.stereoScene.changeViewerModel(model)
    }
    
    func close() {
        // Custom
        DispatchQueue.main.async {
            UIApplication.shared.delegate?.window??.tag = 0
            self.setPortrait()
            Util.disableDeviceGoSleep()
            self.dismiss(animated: true, completion: nil)
        }
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
        playerViews.forEach {
            $0.process = forwardTime
        }
    }
    
    func backward(second: TimeInterval) {
        guard let player = player else { return }
        let currentTime = player.currentTime().seconds
        let backwardTime = currentTime - second
        seek(to: backwardTime, completion: nil)
        playerViews.forEach {
            $0.process = backwardTime
        }
    }
    
    func playNewUrl(url: URL) {
        guard let player = player else { return }
        print("[LOG] Play new url \(url)")
        player.pause()
        if let player = self.player {
            self.panoramaView.scene?.unbind(player)
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }
    
    func stepForward() {
        guard let _ = player, let videos = videos?.items, let currentVideo = currentVideo else { return }
        guard let next = videos.next(item: currentVideo), let url = URL(string: next.url) else { return }
        playNewUrl(url: url)
        currentIndex += 1
        configStepButton()
    }
    
    func stepBackward() {
        guard let _ = player, let videos = videos?.items, let currentVideo = currentVideo else { return }
        guard let prev = videos.prev(item: currentVideo), let url = URL(string: prev.url) else { return }
        playNewUrl(url: url)
        currentIndex -= 1
        configStepButton()
    }
    
    func enterVRMode() {
        guard let _ = videos else { return }
        isStartingVRMode = true
        // Custom
        UIApplication.shared.delegate?.window??.tag = 999
        setStereoMode()
        setLandscape()
        let vc = UIViewController();
        stereoView = PTStereoView(device: panoramaView.device).then {
            // Controller
            let vrControl = PTVRStereoControl()
            vrControl.controller = self
            self.vrControl = vrControl
            if let playerView = playerViews.first {
                vrControl.canStepFoward = playerView.canStepFoward
                vrControl.canStepBackward = playerView.canStepBackward
            }
            $0.renderController.append(vrControl.opacityNode)
            $0.renderController.append(vrControl.playerNode)
            $0.frame = vc.view.frame
            $0.scene = panoramaView.scene
            vrControlView.frame = vc.view.frame
            vc.view.addSubview($0)
            vc.view.insertSubview(vrControlView, aboveSubview: $0)
        }
        navigationController?.pushViewController(vc, animated: false)
        panoramaView.isHidden = true
        panoramaView.scnView.isPlaying = false
        isStartingVRMode = false
    }
    
    func endVRMode() {
        // Custom
        guard let stereoView = stereoView else { return }
        setPanoramaMode()
        UIApplication.shared.delegate?.window??.tag = 99
        navigationController?.popViewController(animated: false)
        stereoView.removeFromSuperview()
        panoramaView.isHidden = false
        panoramaView.scnView.isPlaying = true
        self.stereoView = nil
        self.vrControl = nil
        self.handleOrientation(UIDeviceOrientation.landscapeRight)
        UIApplication.shared.windows.forEach { window in
            if NSStringFromClass(type(of: window)) == "_SCNSnapshotWindow" {
                window.isHidden = true
            }
        }
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
        self.showAlert(message: message, completion: {
            self.dismiss(animated: true, completion: nil)
        })
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
