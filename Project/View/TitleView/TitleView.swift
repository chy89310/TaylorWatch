//
//  TitleView.swift
//  Taylor
//
//  Created by Kevin Sum on 18/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit
import Foundation

class TitleView: DesignableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBInspectable var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    
}
