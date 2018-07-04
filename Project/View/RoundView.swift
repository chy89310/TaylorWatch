//
//  RoundView.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 18/1/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
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
