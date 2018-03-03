//
//  BaseNavigationController.swift
//  Taylor
//
//  Created by Kevin Sum on 23/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import HexColors
import UIKit

class BaseNavigationController: UINavigationController {

    var titleView = TitleView(frame: .zero)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 14)], for: .normal)
        tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -8)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.frame = navigationBar.bounds
        titleView.updateLogo()
        navigationBar.insertSubview(titleView, at: 0)
        
        navigationBar.setTitleVerticalPositionAdjustment(titleView.topConstraint.constant, for: .default)
        let textAttributes = [NSForegroundColorAttributeName: UIColor("#FDDFC0") ?? .white]
        navigationBar.titleTextAttributes = textAttributes
    }
    
}

class BaseNavigationBar: UINavigationBar {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        backgroundColor = UIColor("#323232")
    }
    
}
