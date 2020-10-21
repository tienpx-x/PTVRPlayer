//
//  PTPortraitControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTPortraitControlView: UIView, NibOwnerLoadable, PTControlView {
    // MARK: - IBOutlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var vrButton: UIButton!
    @IBOutlet weak var leftTimeLabel: TimeLabel!
    @IBOutlet weak var rightTimeLabel: TimeLabel!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var closeButton: UIButton!
    
    // MARK: - Properties
    weak var playerController: PTPlayerControler?
    var isPlaying: Bool = false {
        didSet {
            playPauseButton.setImage(isPlaying ? #imageLiteral(resourceName: "ic_pause") : #imageLiteral(resourceName: "ic_play") , for: .normal)
        }
    }
    var isLoading: Bool = false
    
    var duration: TimeInterval = 0 {
        didSet {
            rightTimeLabel.second = duration
            seekSlider.maximumValue = Float(duration)
        }
    }
    
    var process: TimeInterval = 0 {
        didSet {
            leftTimeLabel.second = process
            handleProcess(process)
        }
    }
    
    func handleProcess(_ process: TimeInterval) {
        seekSlider.value = Float(process)
    }
    
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
    
    // MARK: - Methods
    
    func commonInit() {
        containerView.do {
            $0.backgroundColor = #colorLiteral(red: 0.1803921569, green: 0.1921568627, blue: 0.2196078431, alpha: 0.8)
            $0.layer.cornerRadius = 12
        }
        // FIXME
        seekSlider.isEnabled = false
        seekSlider.do {
            $0.setThumbImage(#imageLiteral(resourceName: "ic_slider_oval"), for: .normal)
            $0.tintColor = UIColor.clear
            $0.minimumTrackTintColor = UIColor.white
            $0.maximumTrackTintColor = #colorLiteral(red: 0.7803921569, green: 0.7921568627, blue: 0.8196078431, alpha: 1)
            $0.value = 0.0
        }
    }
    
    func binding() {
        playPauseButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.togglePlayPause()
            })
            .disposed(by: rx.disposeBag)
        
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
    }
}
