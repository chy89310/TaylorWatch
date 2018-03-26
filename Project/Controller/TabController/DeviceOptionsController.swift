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
import MBProgressHUD
import SwiftIconFont
import UIKit

class DeviceOptionsController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var _tableView: UITableView!
    @IBOutlet weak var _addButton: UIButton!
    @IBOutlet weak var _cancelButton: UIButton!
    @IBOutlet weak var _deleteButton: UIButton!
    
    var connectedPeripheral: [CBPeripheral] = []
    var deleteState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localize
        title = NSLocalizedString("CHOOSE A DEVICE", comment: "")
        _addButton.setTitle(NSLocalizedString("Add A Watch", comment: ""), for: .normal)
        _cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        _deleteButton.setTitle(NSLocalizedString("Delete", comment: ""), for: .normal)
        
        updateConnectedPeripheral()
        _tableView.reloadData()
    }
    
    func updateConnectedPeripheral() {
        connectedPeripheral = SBManager.share.peripherals.filter({ (peripheral) -> Bool in
            return peripheral.state == .connected
        }).sorted(by: { (p1, p2) -> Bool in
            p1.identifier.uuidString < p2.identifier.uuidString
        })
    }
    
    func connectTo(peripheral: CBPeripheral) {
        let HUD = MBProgressHUD.showAdded(to: tabBarController?.view ?? view, animated: true)
        DispatchQueue.global().async {
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
                            DispatchQueue.main.async {
                                HUD.hide(animated: true)
                            }
                            SBManager.share.updateSelected(peripheral: peripheral)
                            let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                            Helper.makeRootView(controller: tabController, complete: nil)
                        } else {
                            log.error("Switch watch fail: \(info ?? "Unknow error")")
                            DispatchQueue.main.async {
                                HUD.label.text = info ?? "Unknow error"
                                HUD.hide(animated: true, afterDelay: 2.0)
                            }
                        }
                })
            } else {
                DispatchQueue.main.async {
                    HUD.label.text = NSLocalizedString("Not connected!", comment: "")
                    HUD.hide(animated: true, afterDelay: 2.0)
                }
            }
        }
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
    
    func deleteAt(indexPath: IndexPath) {
        let peripheral = connectedPeripheral[indexPath.row]
        if let url = URL.init(string: "App-Prefs:root=Bluetooth"), UIApplication.shared.canOpenURL(url) {
            let alert = UIAlertController(
                title: NSLocalizedString("Please note that all the history data will be cleared once the device is forgotten from the \"bluetooth settings\".", comment: ""),
                message: "",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                UIApplication.shared.open(url, options: [:], completionHandler: { (finish) in
                    SBManager.share.didDisconnect = {
                        MagicalRecord.save({ (localContext) in
                            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                            device?.mr_deleteEntity(in: localContext)
                        }, completion: { (finish, error) in
                            if let index = SBManager.share.peripherals.index(of: peripheral) {
                                SBManager.share.peripherals.remove(at: index)
                            }
                            self.updateConnectedPeripheral()
                            self._tableView.deleteRows(at: [indexPath], with: .automatic)
                            self._tableView.reloadData()
                            if self.connectedPeripheral.count == 0 {
                                SBManager.share.reset()
                                let scanController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController")
                                Helper.makeRootView(controller: scanController, complete: nil)
                            } else if peripheral == SBManager.share.selectedPeripheral {
                                self.connectTo(peripheral: self.connectedPeripheral[0])
                            }
                        })
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
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
                self.deleteAt(indexPath: indexPath)
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
                let peripheral = self.connectedPeripheral[indexPath.row]
                if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString) {
                    textField.text = device.nickName
                }
            })
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            )
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("Edit", comment: ""), style: .default, handler: { (action) in
                    if let nickName = alert.textFields?.first?.text {
                        MagicalRecord.save(blockAndWait: { (localContext) in
                            let peripheral = self.connectedPeripheral[indexPath.row]
                            if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext) {
                                device.nickName = nickName
                            }
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
        if deleteState {
            deleteAt(indexPath: indexPath)
        } else if connectedPeripheral[indexPath.row] != SBManager.share.selectedPeripheral {
            connectTo(peripheral: connectedPeripheral[indexPath.row])
        } else {
            // do nothing
            tableView.deselectRow(at: indexPath, animated: true)
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
        var color: UIColor? = UIColor.clear
        var fontColor: UIColor? = .white
        if isCurrent {
            color = UIColor("#FDDFC0")
            fontColor = UIColor("4a4a4a")
        }
        backgroundColor = color
        titleLabel.textColor = fontColor
        detailLabel.textColor = fontColor
        trashButton.setTitleColor(fontColor, for: .normal)
    }
}
