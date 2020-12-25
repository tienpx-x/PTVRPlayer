//
//  PTUISlider.swift
//  PTVRPlayer_Example
//
//  Created by Phạm Xuân Tiến on 12/4/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

class PTUISlider: UISlider {
    var trackHeight: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.setMinimumTrackImage(createImage(color: #colorLiteral(red: 0.8935084939, green: 0, blue: 0, alpha: 1), frame: frame), for: .normal)
    }
    
    func createImage(color: UIColor, frame: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        color.setFill()
        UIRectFill(frame)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
