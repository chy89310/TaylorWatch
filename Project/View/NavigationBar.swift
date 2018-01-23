//
//  NavigationBar.swift
//  Taylor
//
//  Created by Kevin Sum on 23/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    var titleView: TitleView?
    @IBOutlet weak var controller: UINavigationController?

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if titleView == nil {
            titleView = TitleView(frame: bounds)
            addSubview(titleView!)
        }
        titleView?.title = controller?.title
        controller?.navigationItem.hidesBackButton = true
    }
    
}
