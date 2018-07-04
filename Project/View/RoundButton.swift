//
//  RoundButton.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 19/1/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import HexColors
import UIKit

@IBDesignable
class RoundButton: UIButton {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = rect.width/2
        layer.masksToBounds = true
        titleLabel?.numberOfLines = 0
        titleLabel?.textAlignment = .center
        titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    func focus(_ focus: Bool) {
        if (focus) {
            setTitleColor(UIColor("#4a4a4a"), for: .normal)
            backgroundColor = UIColor("fddfc0")
        } else {
            setTitleColor(.white, for: .normal)
            backgroundColor = UIColor("#4a4a4a")
        }
    }

}
