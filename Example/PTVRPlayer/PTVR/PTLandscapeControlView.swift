//
//  PTLandscapeControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/2/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTLandscapeControlView: UIView, NibOwnerLoadable, PTControlView {
    // MARK: - IBOutlets
    
    
    // MARK: - Properties
    weak var playerController: PTPlayerControler?
    var isPlaying: Bool = false
    
    var isLoading: Bool = false
    
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
    
    // MARK: - Methods
    
    func commonInit() {
        
    }
    
    func binding() {
        
    }
}
