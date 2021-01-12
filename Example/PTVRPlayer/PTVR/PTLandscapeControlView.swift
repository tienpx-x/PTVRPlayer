//
//  PTLandscapeControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTLandscapeControlView: UIView, NibOwnerLoadable, PTControlView {
    // MARK: - IBOutlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var vrButton: UIButton!
    @IBOutlet weak var leftTimeLabel: TimeLabel!
    @IBOutlet weak var rightTimeLabel: TimeLabel!
    @IBOutlet weak var seekSlider: PTUISlider!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var back30sButton: UIButton!
    @IBOutlet weak var next30sButton: UIButton!
    @IBOutlet weak var focusButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var stepForwardButton: UIButton!
    @IBOutlet weak var stepBackwardButton: UIButton!
    @IBOutlet weak var stepForwardHeight: NSLayoutConstraint!
    @IBOutlet weak var stepBackwardHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    weak var playerController: PTPlayerControler?
    var isPlaying: Bool = false {
        didSet {
            if(isEnded) {
                playPauseButton.setImage(#imageLiteral(resourceName: "ic_replay") , for: .normal)
            } else {
                playPauseButton.setImage(isPlaying ? #imageLiteral(resourceName: "ic_pause") : #imageLiteral(resourceName: "ic_play") , for: .normal)
            }
        }
    }
    var isLoading: Bool = false {
        didSet {
            isLoading ? indicator.startAnimating() : indicator.stopAnimating()
            isLoading ? hideControlView() : showControlView()
        }
    }
    var isSeeking: Bool = false
    var isEnded: Bool = false {
        didSet {
            isPlaying = !isEnded
        }
    }
    
    var duration: TimeInterval = 0 {
        didSet {
            rightTimeLabel.second = duration
            seekSlider.maximumValue = Float(duration)
        }
    }
    
    var availableDuration: TimeInterval = 0 {
        didSet {
            seekSlider.progressView.progress = Float(availableDuration / duration)
        }
    }
    
    var process: TimeInterval = 0 {
        didSet {
            handleProcess(process)
            updateControllersState()
        }
    }
    
    var canStepFoward: Bool = false {
        didSet {
            stepForwardHeight.constant = canStepFoward ? 30 : 0
        }
    }
    
    var canStepBackward: Bool = false {
        didSet {
            stepBackwardHeight.constant = canStepBackward ? 30 : 0
        }
    }
    
    // MARK: - Timer
    private(set) var timerController: Timer?
    private(set) var timerShowTimeCounting: Int = 0
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
        self.binding()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadNibContent()
        self.commonInit()
        self.binding()
    }
    
    deinit {
        stopTrackingControllerShowTime()
        print(String(describing: type(of: self)) + " deinit")
    }
    
    // MARK: - Methods
    
    func commonInit() {
        startTrackingControllerShowTime()
        containerView.do {
            $0.backgroundColor = #colorLiteral(red: 0.1803921569, green: 0.1921568627, blue: 0.2196078431, alpha: 0.8)
            $0.layer.cornerRadius = 12
        }
        seekSlider.isEnabled = true
        seekSlider.do {
            $0.setThumbImage(#imageLiteral(resourceName: "ic_slider_oval"), for: .normal)
            $0.tintColor = UIColor.clear
            $0.minimumTrackTintColor = .red
            $0.maximumTrackTintColor = .clear
            $0.value = 0.0
            $0.addTarget(self, action: #selector(handleSliderEvent(_:forEvent:)), for: .valueChanged)
        }
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showControlView)))
    }
    
    func binding() {
        playPauseButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                if self.isEnded {
                    self.isEnded = false
                    self.playerController?.seek(to: TimeInterval.zero, completion: nil)
                } else {
                    self.playerController?.togglePlayPause()
                }
            })
            .disposed(by: rx.disposeBag)
        
        back30sButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                if self.isEnded {
                    self.isEnded = false
                }
                self.playerController?.backward(second: 30)
            })
            .disposed(by: rx.disposeBag)
        
        next30sButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                if self.isEnded {
                    self.isEnded = false
                }
                self.playerController?.forward(second: 30)
            })
            .disposed(by: rx.disposeBag)

        [back30sButton, next30sButton, playPauseButton].forEach {
            $0.rx.controlEvent(.touchUpInside)
                .subscribe(onNext: { [unowned self] _ in
                    self.resetTrackingControllerShowTime()
                })
                .disposed(by: rx.disposeBag)
        }

        vrButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.enterVRMode()
            })
            .disposed(by: rx.disposeBag)
        
        closeButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.close()
            })
            .disposed(by: rx.disposeBag)
        
        focusButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.focus(true)
            })
            .disposed(by: rx.disposeBag)
        
        seekSlider.rx.value.asDriver()
            .do(onNext: { [unowned self] value in
                self.process = TimeInterval(value)
            })
            .drive()
            .disposed(by: rx.disposeBag)
        
        stepForwardButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in
                self.playerController?.stepForward()
            })
            .disposed(by: rx.disposeBag)
        
        stepBackwardButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in
                self.playerController?.stepBackward()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func handleProcess(_ process: TimeInterval) {
        guard !isSeeking else { return }
        leftTimeLabel.second = process
        seekSlider.value = Float(process)
    }
    
    func updateControllersState() {
        let canBack = process > 0.1
        back30sButton.isEnabled = canBack
    }
    
    @objc func handleSliderEvent(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touchEvent = event.allTouches?.first else { return }
        switch touchEvent.phase {
        case .began:
            stopTrackingControllerShowTime()
            self.isSeeking = true
        case .moved:
            leftTimeLabel.second = TimeInterval(sender.value)
        case .ended:
            resetTrackingControllerShowTime()
            self.playerController?.seek(to: TimeInterval(sender.value), completion: nil)
            self.isSeeking = false
        case .cancelled:
            resetTrackingControllerShowTime()
            self.isSeeking = false
        default:
            resetTrackingControllerShowTime()
            self.isSeeking = false
            break
        }
    }
}

extension PTLandscapeControlView {
    @objc func showControlView() {
        guard !isLoading else { return }
        resetTrackingControllerShowTime()
        self.containerView.isHidden = false
        self.closeButton.isHidden = false
    }
    
    @objc func hideControlView() {
        self.containerView.isHidden = true
        self.closeButton.isHidden = true
    }
    
    func startTrackingControllerShowTime() {
        if !(timerController?.isValid ?? false) {
            timerController = Timer.scheduledTimer(timeInterval: 1,
                                                   target: self,
                                                   selector: #selector(handleTimerCounting),
                                                   userInfo: nil,
                                                   repeats: true)
        }
        timerShowTimeCounting = 0
    }
    
    func stopTrackingControllerShowTime() {
        if let timer = timerController, timer.isValid {
            timer.invalidate()
        }
        timerController = nil
        timerShowTimeCounting = 0
    }
    
    func resetTrackingControllerShowTime() {
        stopTrackingControllerShowTime()
        startTrackingControllerShowTime()
    }
    
    @objc func handleTimerCounting() {
        timerShowTimeCounting += 1
        
        if timerShowTimeCounting > 5 {
            stopTrackingControllerShowTime()
            hideControlView()
        }
    }
}
