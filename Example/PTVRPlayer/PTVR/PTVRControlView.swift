//
//  PTVRControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/5/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTVRControlView: UIView, NibOwnerLoadable, PTControlView {
    // MARK: - IBOutlets
    
    @IBOutlet weak var closeButton: UIButton!
    
    // MARK: - Properties
    weak var playerController: PTPlayerControler?
    
    var isPlaying: Bool = false
    
    var isLoading: Bool = false
    
    var isSeeking: Bool = false
    
    var isEnded: Bool = false
    
    var duration: TimeInterval = 0 {
        didSet {
            
        }
    }
    
    var process: TimeInterval = 0 {
        didSet {
            
        }
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let view = subviews.first?.subviews.first else { return false }
        return view.hitTest(convert(point, to: view), with: event) != nil
    }
    
    // MARK: - Methods
    
    func commonInit() {
        
    }
    
    func binding() {
        closeButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.endVRMode();
            })
            .disposed(by: rx.disposeBag)
    }
    
    @objc func showControlView() {
        
    }
    
    @objc func hideControlView() {
        
    }
}
