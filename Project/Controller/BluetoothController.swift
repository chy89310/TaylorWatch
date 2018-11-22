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

        SBManager.share.didPowerOn = {
            let scanController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController")
            Helper.makeRootView(controller: scanController, complete: nil)
        }
        bluetoothButton.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)
    }
    
    func didButtonClick() {
        if let url = URL.init(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}
