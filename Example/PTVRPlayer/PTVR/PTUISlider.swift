//
//  PTUISlider.swift
//  PTVRPlayer_Example
//
//  Created by Phạm Xuân Tiến on 12/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTUISlider: UISlider {
    let progressView =  UIProgressView(progressViewStyle: .default)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        progressView.do {
            $0.isUserInteractionEnabled = false
            $0.progressTintColor = #colorLiteral(red: 0.8821555577, green: 0.8952404663, blue: 0.9344951923, alpha: 1)
            $0.trackTintColor = #colorLiteral(red: 0.7803921569, green: 0.7921568627, blue: 0.8196078431, alpha: 0.7)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let left = NSLayoutConstraint(item: progressView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: progressView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0.75)
        let right = NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        addConstraints([left, right, centerY])
        addSubview(progressView)
        sendSubviewToBack(progressView)
    }
}
