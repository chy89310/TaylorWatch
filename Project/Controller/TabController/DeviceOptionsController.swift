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

class DeviceOptionsController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var _tableView: UITableView!
    
    var deleteState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                let alert = UIAlertController(
                    title: NSLocalizedString("Please note that all the history data including pairing code and health management will be cleared", comment: ""),
                    message: NSLocalizedString("Please turn off your smart watch connection in Apple Notification Center Service (ANCS) in the Settings, and get back to app.", comment: ""),
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
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
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as? DeviceOptionsCell {
            if indexPath.row%2 == 0 {
                cell.backgroundColor = UIColor("#4a4a4a")
            } else {
                cell.backgroundColor = UIColor("#9b9b9b")
            }
            let device = Device.mr_findAll()?[indexPath.row] as? Device ?? Device()
            cell.titleLabel.text = device.nickName
            UIView.animate(withDuration: 0.2, animations: {
                cell.detailLabel.alpha = self.deleteState ? 0.0 : 1.0
                cell.detailLabel.isHidden = self.deleteState
                cell.trashButton.alpha = self.deleteState ? 1.0 : 0.0
                cell.trashButton.isHidden = !self.deleteState
            })
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
    
    // Mark: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScan", let scanController = segue.destination as? ScanViewController {
            let backItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .plain, target: scanController, action: #selector(ScanViewController.backAction))
            backItem.tintColor = .white
            scanController.navigationItem.leftBarButtonItem = backItem
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
