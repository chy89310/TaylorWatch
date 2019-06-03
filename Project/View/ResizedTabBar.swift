//
//  ResizedTabBar.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 25/3/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import UIKit

class ResizedTabBar: UITabBar {

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var newSize = super.sizeThatFits(size)
        for item in items ?? [] {
            // iPhone X tabbar heigth is 83 by default
            if newSize.height > 70 {
                item.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .normal)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
            } else {
                newSize.height = 70
                item.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], for: .normal)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
            }
            item.title = NSLocalizedString(item.title ?? "", comment: "")
        }
        return newSize
    }

}
