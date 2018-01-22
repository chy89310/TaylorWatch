//
//  DeviceOptionsController.swift
//  Taylor
//
//  Created by Kevin Sum on 21/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import HexColors
import MagicalRecord
import SwiftIconFont
import UIKit

class DeviceOptionsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var _tableView: UITableView!
    
    var deleteState = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    @IBAction func didCancelClick(_ sender: UIButton) {
        if deleteState {
            didDeleteClick(UIButton())
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func didDeleteClick(_ sender: UIButton) {
        deleteState = !deleteState
        _tableView.reloadData()
    }
    
    func deleteAt(index: Int) {
        if let peripheral = SBManager.share.selectedPeripheral {
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
    
    // Mark: - UITableView datasource deletegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Device.mr_findAll()?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as? DeviceOptionsCell {
            if indexPath.row%2 == 0 {
                cell.backgroundColor = UIColor("#4a4a4a")
            } else {
                cell.backgroundColor = UIColor("#9b9b9b")
            }
            let device = Device.mr_findAll()?[indexPath.row] as? Device ?? Device()
            cell.titleLabel.text = device.name
            cell.detailLabel.isHidden = deleteState
            cell.trashButton.isHidden = !deleteState
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = (device.addDate ?? NSDate()) as Date
            cell.detailLabel.text = formatter.string(from: date)
            cell.didDelete = {
                self.deleteAt(index: indexPath.row)
            }

            return cell
        } else {
            return DeviceOptionsCell()
        }
    }    

}

class DeviceOptionsCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var trashButton: UIButton!
    
    var didDelete: (() -> ())?
    
    @IBAction func didTrashClick(_ sender: UIButton) {
        didDelete?()
    }
    
    
}
