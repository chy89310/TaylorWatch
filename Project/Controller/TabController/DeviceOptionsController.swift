//
//  DeviceOptionsController.swift
//  Taylor
//
//  Created by Kevin Sum on 21/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import CoreBluetooth
import HexColors
import MagicalRecord
import SwiftIconFont
import UIKit

class DeviceOptionsController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var _tableView: UITableView!
    var connectedPeripheral: [CBPeripheral] = []
    var deleteState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        connectedPeripheral = SBManager.share.peripherals.filter({ (peripheral) -> Bool in
            if peripheral.state == CBPeripheralState.connected {
                return true
            } else {
                return false
            }
        })
        _tableView.reloadData()
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
        return connectedPeripheral.count
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
            let peripheral = connectedPeripheral[indexPath.row]
            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
            cell.titleLabel.text = device?.nickName ?? "N/A"
            cell.setCurrent(SBManager.share.selectedPeripheral == peripheral)
            UIView.animate(withDuration: 0.2, animations: {
                cell.detailLabel.alpha = self.deleteState ? 0.0 : 1.0
                cell.detailLabel.isHidden = self.deleteState
                cell.trashButton.alpha = self.deleteState ? 1.0 : 0.0
                cell.trashButton.isHidden = !self.deleteState
            })
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = (device?.addDate ?? NSDate()) as Date
            cell.detailLabel.text = formatter.string(from: date)
            cell.didDelete = {
                self.deleteAt(index: indexPath.row)
            }

            return cell
        } else {
            return DeviceOptionsCell()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .default, title: NSLocalizedString("Edit", comment: "")) { (action, indexPath) in
            let alert = UIAlertController(title: NSLocalizedString("Edit Nick Name", comment: ""), message: "", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                let device = Device.mr_findAll()?[indexPath.row] as? Device ?? Device()
                textField.text = device.nickName
            })
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            )
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("Edit", comment: ""), style: .default, handler: { (action) in
                    if let nickName = alert.textFields?.first?.text {
                        MagicalRecord.save(blockAndWait: { (localContext) in
                            let device = Device.mr_findAll(in: localContext)?[indexPath.row] as? Device
                            device?.nickName = nickName
                        })
                        tableView.reloadData()
                    }
                })
            )
            self.present(alert, animated: true, completion: nil)
        }
        action.backgroundColor = UIColor("#FDDFC0")
        return [action]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = connectedPeripheral[indexPath.row]
        if peripheral != SBManager.share.selectedPeripheral,
            peripheral.state == .connected,
            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString),
            device.passcode != 0xffff {
            SBManager.share.updateSelected(peripheral: peripheral)
            SBManager.share.pairing(
                passkey: Int(device.passcode),
                peripheral: peripheral,
                complete: { (success, info) in
                    if success {
                        SBManager.share.updateSelected(peripheral: peripheral)
                        SBManager.share.subscribeToANCS(true)
                        // Set notification
//                        var enabledTypes: [SBManager.MESSAGE_TYPE] = []
//                        for (type, _) in SBManager.share.messageMap {
//                            if device.notification?.isTypeOn(type) ?? false {
//                                enabledTypes.append(type)
//                            }
//                        }
//                        SBManager.share.setMessageEnabled(with: enabledTypes)
                        log.debug("Make root view with tab controller when switch watch")
                        SBManager.share.selectedPeripheral = peripheral
                        let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.window?.rootViewController = tabController
                    } else {
                        log.error("Switch watch fail: \(info)")
                    }
            })
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
    
    func setCurrent(_ isCurrent: Bool) {
        if isCurrent {
            titleLabel.textColor = UIColor("#FDDFC0")
            detailLabel.textColor = UIColor("#FDDFC0")
        } else {
            titleLabel.textColor = .white
            detailLabel.textColor = .white
        }
    }
}
