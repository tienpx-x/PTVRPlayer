//
//  PTVRSettings.swift
//  PTVRPlayer_Example
//
//  Created by Phạm Xuân Tiến on 12/23/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import FontAwesome_swift

class PTVRSettings: UIView, NibOwnerLoadable {
    @IBOutlet weak var viewerImageView: UIImageView!
    @IBOutlet weak var viewerLabel: UILabel!
    @IBOutlet weak var viewerButton: UIButton!
    
    @IBOutlet weak var subImageView: UIImageView!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var subButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadNibContent()
        self.commonInit()
    }
    
    func commonInit() {
        viewerImageView.image = UIImage.fontAwesomeIcon(name: .vrCardboard,
                                                        style: .solid,
                                                        textColor: .black,
                                                        size: CGSize(width: 40, height: 40))
        viewerLabel.text = "ビューア切り替え： Cardboard"
        
        subImageView.image = UIImage.fontAwesomeIcon(name: .undo,
                                                     style: .solid,
                                                     textColor: .black,
                                                     size: CGSize(width: 40, height: 40))
        subLabel.text = "Cardboardにリセットする"
    }
}
