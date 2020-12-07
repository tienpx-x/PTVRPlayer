//
//  TimeLabel.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/6/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class TimeLabel: UILabel {
    var second: TimeInterval = 0 {
        didSet {
            guard !second.isInfinite, !second.isNaN else {
                self.text = "00:00"
                return
            }
            if second >= 0 {
                self.text = second.toString()
            } else {
                self.text = "- \((-second).toString())"
                if self.text == "- 00:00" {
                    self.text = "00:00"
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    fileprivate func setupView() {
        textColor = UIColor.white
        text = "00:00"
    }
}

extension TimeInterval {
    func toHourMinutesSeconds() -> (Int, Int, Int) {
        guard self > 0 else {
            return (0, 0, 0)
        }
        let hours = floor(self / (60 * 60))
        let minutes = floor((self - hours * (60 * 60)) / 60)
        let seconds = trunc(self - hours * (60 * 60) - minutes * 60)
        
        return (Int(hours), Int(minutes), Int(seconds))
    }
    
    func toString() -> String {
        let hms = toHourMinutesSeconds()
        let hour = hms.0
        let minute = hms.1
        let second = hms.2
        let hourStr = String(format: "%02d", hour)
        let minuteStr = String(format: "%02d", minute)
        let secondStr = String(format: "%02d", second)
        if hour == 0 {
            return "\(minuteStr):\(secondStr)"
        } else {
            return "\(hourStr):\(minuteStr):\(secondStr)"
        }
    }
}
