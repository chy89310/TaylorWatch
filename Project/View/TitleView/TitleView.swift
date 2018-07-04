//
//  TitleView.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 18/1/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import UIKit
import Foundation

class TitleView: DesignableView {
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBInspectable var title: String?
    @IBOutlet weak var logoImage: UIImageView!
    
    func updateLogo() {
        logoImage.image = SBManager.share.getAsset(.logo)
    }
    
}
