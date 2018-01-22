//
//  RoundView.swift
//  Taylor
//
//  Created by Kevin Sum on 18/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

@IBDesignable
class RoundView: UIView {

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = rect.width/2
        layer.masksToBounds = true
    }

}
