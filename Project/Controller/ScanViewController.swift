//
//  ScanViewController.swift
//  Taylor
//
//  Created by Kevin on 23/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer
import MagicalRecord

class ScanViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var _pickerView: UIPickerView!
    @IBOutlet weak var _collectionView: UICollectionView!
    @IBOutlet weak var _watchView: WatchView!
    var textField: UITextField?
    var passcode: String?
    var easterEgg: [CGFloat] = [1,1,-1,-1,1,-1,-1]
    var volume: CGFloat = 0.0
    var isSimulator = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG && (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            isSimulator = true
        #endif
        
        // Remove all not paired device
        MagicalRecord.save(blockAndWait: { (localContext) in
            let predicate = NSPredicate(format: "passcode == %d", 0xffff)
            for device in Device.mr_findAll(with: predicate, in: localContext) as! [Device] {
                device.mr_deleteEntity(in: localContext)
            }
        })
        
        // Easter egg
        let volumeView = MPVolumeView(frame: CGRect(x: -CGFloat.greatestFiniteMagnitude, y: 0, width: 0, height: 0))
        self.view.addSubview(volumeView)
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        log.debug("Devices count: \(Device.mr_findAll()?.count ?? 0)")
        for device in Device.mr_findAll()! as! [Device] {
            log.debug("\(device.name) \(device.uuid) \(device.passcode)")
        }
        SBManager.share.scanAction()
        SBManager.share.didFindDevice = { (peripheral) in
            log.debug("Find device: \(peripheral)")
            self._collectionView.reloadData()
        }
        
        _collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(false, animated: true)
        _watchView.watchFace.animate(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        _watchView.watchFace.animate(false)
    }
    
    func volumeChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String == "ExplicitVolumeChange",
            let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? CGFloat {
            let change = volume - self.volume
            self.volume = volume
            if change*easterEgg[0] > 0 {
                easterEgg.remove(at: 0)
                if easterEgg.count == 0 {
                    performSegue(withIdentifier: "showProfile", sender: nil)
                }
            } else {
                // Game over
                easterEgg.insert(0, at: 0)
            }
        }
    }

    func connectAction() {
        if let row = _collectionView.indexPathsForSelectedItems?[0].row {
            let peripheral = SBManager.share.peripherals[row]
            let passInt = Int(passcode ?? "0") ?? 0
            SBManager.share.pairing(
                passkey: passInt,
                peripheral: peripheral,
                complete: { (success, info) in
                    if success {
                        SBManager.share.updateSelected(peripheral: peripheral)
                        SBManager.share.subscribeToANCS(true)
                        // Save current device
                        MagicalRecord.save({ (localContext) in
                            SBManager.share.selectedDevice(in: localContext)?.passcode = Int32(passInt)
                        })
                        // reset notification
                        SBManager.share.setMessageEnabled(with: [])
                        self.performSegue(withIdentifier: "showProfile", sender: nil)
                    } else {
                        log.error(info)
                        SBManager.share.didUpdateValue = nil
                        self.textField?.isEnabled = true
                        self.textField?.becomeFirstResponder()
                        SBManager.share.peripheral(peripheral, write: Data.init(bytes: Helper.stringToBytes("00ffff")))
                    }
            })
        }
    }
    
    func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    // Mark: - UICollectionView datasource and delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isSimulator {
            return 1
        } else {
            return SBManager.share.peripherals.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isSimulator {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "simulatorCell", for: indexPath)
        } else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCell", for: indexPath) as? ScanViewCell {
            let peripheral = SBManager.share.peripherals[indexPath.row]
            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
            cell.titleLabel.text = device?.name ?? "N/A"
            if peripheral == SBManager.share.selectedPeripheral {
                cell.titleLabel.textColor = UIColor("#323232")
            } else {
                cell.titleLabel.textColor = UIColor("#FDDFC0")
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSimulator {
            performSegue(withIdentifier: "showProfile", sender: nil)
            return
        }
        let peripheral = SBManager.share.peripherals[indexPath.row]
        if peripheral != SBManager.share.selectedPeripheral {
        SBManager.share.centralManager.stopScan()
        SBManager.share.centralManager.connect(peripheral, options: nil)
        if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString), device.passcode != 0xffff {
            log.debug("Remember device with passcode: \(device.passcode)")
            SBManager.share.didFindCharacter = { (characteristic) in
                if characteristic.properties.rawValue == 4 {
                    SBManager.share.pairing(
                        passkey: Int(device.passcode),
                        peripheral: peripheral,
                        complete: { (success, info) in
                            if success {
                                SBManager.share.selectedPeripheral = peripheral
                                self.performSegue(withIdentifier: "showWatch", sender: nil)
                            } else {
                                log.error(info)
                            }
                    })
                }
            }
        } else {
            log.debug("New device!")
            SBManager.share.didUpdateValue = { (character) in
                SBManager.share.didUpdateValue = nil
                let alertController = UIAlertController(
                    title: NSLocalizedString("Please enter the number that hour hand and minute hand indicate separately", comment: ""),
                    message: NSLocalizedString("This code will be saved in info. It will be needed when you connect to the new mobile and want to log with history data.", comment: ""),
                    preferredStyle: .alert)
                alertController.addTextField(configurationHandler: { (textFiled) in
                    self.textField = textFiled
                    textFiled.inputView = self._pickerView
                    textFiled.textAlignment = .center
                })
                alertController.addAction(UIAlertAction(
                    title: NSLocalizedString("OK", comment: ""),
                    style: .default,
                    handler: { (action) in
                        self.passcode = self.textField?.text
                        self.connectAction()
                        self.textField = nil
                }))
                alertController.addAction(UIAlertAction(
                    title: NSLocalizedString("Cancel", comment: ""),
                    style: .cancel,
                    handler: { (action) in
                        self.textField = nil
                }))
                self.present(alertController, animated: true, completion: nil)
                SBManager.share.peripheral(peripheral, write: Data.init(bytes: Helper.stringToBytes("00ffff")))
            }
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
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: titleForRow(row: row, forComponent: component),
                                  attributes: [NSForegroundColorAttributeName: UIColor("#FDDFC0")])
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titleForRow(row: row, forComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hour = titleForRow(row: pickerView.selectedRow(inComponent: 0), forComponent: 0)
        let minus = titleForRow(row: pickerView.selectedRow(inComponent: 1), forComponent: 1)
        textField?.text = "\(hour)\(minus)"
    }
    
    // Mark: - UITextfield delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.isEnabled = false
    }

}

@IBDesignable
class ScanViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = rect.width/2
        layer.masksToBounds = true
    }
}
