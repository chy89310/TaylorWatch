//
//  BluetoothController.swift
//  Taylor
//
//  Created by Kevin on 01/03/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

class BluetoothController: BaseViewController {

    @IBOutlet weak var bluetoothButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        bluetoothButton.isEnabled = false
    }

}
