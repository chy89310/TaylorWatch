//
//  ScanViewController.swift
//  Taylor
//
//  Created by Kevin on 23/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScanViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var _tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        TaylorCentralManager.sharedInstance.connectAction()
        TaylorCentralManager.sharedInstance.didFindDevice = { (peripheral) in
            log.debug("Find device: \(peripheral)")
            self._tableView.reloadData()
        }
    }

    // Mark: - Table view datasource and delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TaylorCentralManager.sharedInstance.devices.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peripheral = Array(TaylorCentralManager.sharedInstance.devices.keys)[indexPath.row]
        let advertisement = TaylorCentralManager.sharedInstance.devices[peripheral]
        cell.textLabel?.text = advertisement?[CBAdvertisementDataLocalNameKey] as? String ?? ""
        
        return cell
    }
    
    // Mark: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showDeviceInfo") {
            let deviceInfo = segue.destination as! DeviceInfoViewController
            let indexPath = _tableView.indexPathForSelectedRow ?? IndexPath.init(row: 0, section: 0)
            let peripheral = Array(TaylorCentralManager.sharedInstance.devices.keys)[indexPath.row]
            let advertisement = TaylorCentralManager.sharedInstance.devices[peripheral]
            deviceInfo.peripheral = peripheral
            deviceInfo.advertisement = advertisement
            
        }
    }

}
