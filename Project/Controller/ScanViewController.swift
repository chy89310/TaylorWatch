//
//  ScanViewController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 23/11/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer
import MagicalRecord
import SwiftyJSON
import SpringIndicator

class ScanViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var _pickerView: UIPickerView!
    @IBOutlet weak var _collectionView: UICollectionView!
    @IBOutlet weak var _watchView: WatchView!
    @IBOutlet weak var _backButton: UIButton!
    var textField: UITextField?
    var passcode: String?
    var easterEgg: [CGFloat] = [1,1,-1,-1,1,-1,-1]
    var volume: CGFloat = 0.0
    var isSimulator = false
    var hideBackButton = true
    var privacyJson: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _backButton.setTitle(NSLocalizedString("Back", comment: ""), for: .normal)
        _backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        _backButton.isHidden = hideBackButton
        
        #if DEBUG && (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            isSimulator = true
        #endif
        
        // Easter egg
        let volumeView = MPVolumeView(frame: CGRect(x: -CGFloat.greatestFiniteMagnitude, y: 0, width: 0, height: 0))
        self.view.addSubview(volumeView)
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        log.debug("Devices count: \(Device.mr_findAll()?.count ?? 0)")
        for device in Device.mr_findAll()! as! [Device] {
            log.debug("\(String(describing: device.name)) \(String(describing: device.uuid)) \(device.passcode)")
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
        _watchView.watchFace.animate(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        _watchView.watchFace.animate(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        log.debug("Stop scanning")
        SBManager.share.centralManager.stopScan()
    }
    
    @objc func volumeChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String == "ExplicitVolumeChange",
            let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? CGFloat {
            let change = volume - self.volume
            self.volume = volume
            if easterEgg.count > 0, change*easterEgg[0] > 0 {
                easterEgg.remove(at: 0)
                if easterEgg.count == 0 {
                    performSegue(withIdentifier: "showLogin", sender: nil)
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
                        self.performSegue(withIdentifier: "showLogin", sender: nil)
                    } else {
                        log.error(String(describing: info))
                        SBManager.share.didUpdateValue = nil
                        self.textField?.isEnabled = true
                        self.textField?.becomeFirstResponder()
                        SBManager.share.peripheral(peripheral, write: Data.init(bytes: Helper.stringToBytes("00ffff")))
                    }
            })
        }
    }
    
    func disconnectAction() {
        if let row = _collectionView.indexPathsForSelectedItems?[0].row {
            let peripheral = SBManager.share.peripherals[row]
            SBManager.share.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    func showPrivacy(_ json: JSON?) {
        privacyJson = json
        performSegue(withIdentifier: "showPrivacy", sender: nil)
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
            cell.titleLabel.text = device?.nickName ?? device?.name ?? "N/A"
            if peripheral.state == .connected {
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
            performSegue(withIdentifier: "showLogin", sender: nil)
            return
        }
        let peripheral = SBManager.share.peripherals[indexPath.row]
        if peripheral != SBManager.share.selectedPeripheral {
            let cell = collectionView.cellForItem(at: indexPath) as? ScanViewCell
            cell?.indicator.start()
            SBManager.share.centralManager.stopScan()
            SBManager.share.centralManager.connect(peripheral, options: nil)
            if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString), device.passcode != 0xffff {
                log.debug("Remember device with passcode: \(device.passcode)")
                SBManager.share.didPaired = { (peripheral, success, info) in
                    if success {
                        SBManager.share.selectedPeripheral = peripheral
                        self.performSegue(withIdentifier: "showWatch", sender: nil)
                    } else {
                        log.error(info ?? "")
                    }
                }
            } else {
                log.debug("New device!")
                SBManager.share.didUpdateValue = { (character) in
                    cell?.indicator.stop()
                    SBManager.share.didUpdateValue = nil
                    let alertController = UIAlertController(
                        title: NSLocalizedString("Please enter the time indicated on your watch.", comment: ""),
                        message: NSLocalizedString("HOURS : MINUTES", comment: ""),
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
                            self.disconnectAction()
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
                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor("#FDDFC0") ?? .white])
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
    
    // Mark: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPrivacy", let privacyController = segue.destination as? PrivacyController {
            privacyController.json = privacyJson
        }
    }

}

@IBDesignable
class ScanViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var indicator: SpringIndicator!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = rect.width/2
        layer.masksToBounds = true
    }
}
