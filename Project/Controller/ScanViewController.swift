//
//  ScanViewController.swift
//  Taylor
//
//  Created by Kevin on 23/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth
import MagicalRecord

class ScanViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var _tableView: UITableView!
    @IBOutlet weak var _textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.debug("Devices count: \(Device.mr_findAll()?.count)")
        for device in Device.mr_findAll()! as! [Device] {
            log.debug("\(device.name) \(device.uuid) \(device.passcode)")
        }
        SBManager.share.connectAction()
        SBManager.share.didFindDevice = { (peripheral) in
            log.debug("Find device: \(peripheral)")
            self._tableView.reloadData()
        }
        
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        _textField.inputView = pickerView
        _textField.delegate = self
        _tableView.reloadData()
    }

    @IBAction func didConnectClick(_ sender: Any) {
        if let row = _tableView.indexPathForSelectedRow?.row {
            let peripheral = SBManager.share.peripherals[row]
            let passInt = Int(_textField.text ?? "0") ?? 0
            let value = SBManager.share.pairing(passkey: passInt)
            SBManager.share.didUpdateEvent = { (evt, data) in
                if evt == .notify {
                    SBManager.share.didUpdateEvent = nil
                    SBManager.share.selectedPeripheral = peripheral
                    // Save current device
                    MagicalRecord.save({ (localContext) in
                        SBManager.share.selectedDevice(in: localContext)?.passcode = Int32(passInt)
                    })
                    self.performSegue(withIdentifier: "showWatch", sender: nil)
                }
            }
            SBManager.share.peripheral(peripheral, write: value)
            
        }
    }
    
    // Mark: - Table view datasource and delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SBManager.share.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peripheral = SBManager.share.peripherals[indexPath.row]
        let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
        cell.textLabel?.text = device?.name ?? "N/A"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = SBManager.share.peripherals[indexPath.row]
        SBManager.share.centralManager.stopScan()
        SBManager.share.centralManager.connect(peripheral, options: nil)
        if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString), device.passcode != 0xffff {
            log.debug("Remember device with passcode: \(device.passcode)")
            let value = SBManager.share.pairing(passkey: Int(device.passcode))
            SBManager.share.didFindCharacter = { (characteristic) in
                if characteristic.properties.rawValue == 4 {
                    SBManager.share.peripheral(peripheral, write: value)
                }
            }
            SBManager.share.didUpdateEvent = { (evt, data) in
                if evt == .notify {
                    SBManager.share.didUpdateEvent = nil
                    SBManager.share.selectedPeripheral = peripheral
                    self.performSegue(withIdentifier: "showWatch", sender: nil)
                }
            }
        } else {
            log.debug("New device!")
            SBManager.share.didUpdateValue = { (character) in
                SBManager.share.didUpdateValue = nil
                self._textField.isEnabled = true
                self._textField.becomeFirstResponder()
                SBManager.share.peripheral(peripheral, write: Data.init(bytes: Helper.stringToBytes("00ffff")))
            }
        }
    }
    
    // Mark: - PickerView datasource and delegate
    
    func titleForRow(row: Int, forComponent component: Int) -> String {
        if component == 0 {
            if (row < 10) {
                return "0\(row)"
            } else {
                return "\(row)"
            }
        } else {
            if (row < 2) {
                return "0\(row*5)"
            } else {
                return "\(row*5)"
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 12
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titleForRow(row: row, forComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hour = titleForRow(row: pickerView.selectedRow(inComponent: 0), forComponent: 0)
        let minus = titleForRow(row: pickerView.selectedRow(inComponent: 1), forComponent: 1)
        _textField.text = "\(hour)\(minus)"
    }
    
    // Mark: - UITextfield delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        _textField.isEnabled = false
    }

}
