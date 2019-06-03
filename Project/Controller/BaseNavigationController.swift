//
//  BaseNavigationController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 23/1/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import HexColors
import UIKit

class BaseNavigationController: UINavigationController {

    var titleView = TitleView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.frame = navigationBar.bounds
        titleView.updateLogo()
        navigationBar.insertSubview(titleView, at: 0)
        
        navigationBar.setTitleVerticalPositionAdjustment(titleView.topConstraint.constant, for: .default)
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor("#FDDFC0") ?? .white]
        navigationBar.titleTextAttributes = textAttributes
    }
    
}

class BaseNavigationBar: UINavigationBar {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        backgroundColor = UIColor("#323232")
    }
    
}
