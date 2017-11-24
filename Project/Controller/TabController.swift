//
//  TabController.swift
//  Taylor
//
//  Created by Kevin Sum on 10/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit

class TabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // always subscribe the ancs
        SBManager.share.peripheral(
            SBManager.share.selectedPeripheral,
            write: Data.init(bytes: [0x0d,0xaa]))
    }
    
}
