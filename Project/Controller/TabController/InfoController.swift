//
//  InfoController.swift
//  Taylor
//
//  Created by Kevin Sum on 28/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import MagicalRecord
import UIKit

class InfoController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) ?? Device()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textColor = .black
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Name: \(device.name!)"
        case 1:
            cell.textLabel?.text = "Serial NO.: \(device.serial!)"
        case 2:
            cell.textLabel?.text = "System NO.: \(device.system!)"
        case 3:
            cell.textLabel?.text = "Firmware: \(device.firmware!)"
        case 4:
            cell.textLabel?.text = "Manufacturer: \(device.manufacturer!)"
        case 5:
            cell.textLabel?.text = "Passcode: \(device.passcode)"
        case 6:
            cell.textLabel?.text = "Battery: \(device.battery)"
        case 7:
            cell.textLabel?.text = "Delete device"
            cell.textLabel?.textColor = .red
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 7, let peripheral = SBManager.share.selectedPeripheral {
            if let url = URL.init(string: "App-Prefs:root=Bluetooth"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { (finish) in
                    SBManager.share.didDisconnect = {
                        MagicalRecord.save({ (localContext) in
                            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                            device?.mr_deleteEntity(in: localContext)
                        }, completion: { (finish, error) in
                            SBManager.share.reset()
                            log.debug("Make root view with scan controller")
                            let scanController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController")
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.window?.rootViewController = scanController
                        })
                    }
                })
            }
        }
    }

}
