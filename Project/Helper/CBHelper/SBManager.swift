//
//  SBManager.swift
//  Project
//
//  Created by Kevin on 22/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import AVFoundation
import MagicalRecord
import UIKit
import CoreBluetooth
import SwiftyJSON

class SBManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Property

    static let share = SBManager()
    static let restoreID = "tayler.central.id"
    var centralManager = CBCentralManager.init(delegate: nil, queue: nil)
    var peripherals = [CBPeripheral]()
    var selectedPeripheral: CBPeripheral?
    var player: AVAudioPlayer?
    var writeCharacteristic = [CBPeripheral:CBCharacteristic]()
    var messageOffset: [SBManager.MESSAGE_TYPE:Int] = [:]
    
    // MARK: - Callback methods
    
    var didFindDevice: ((CBPeripheral) -> ())?
    var didPaired: ((CBPeripheral, Bool, String?) -> ())?
    var didPowerOn: (() -> ())?
    var didUpdateValue: ((CBCharacteristic) -> ())?
    var didUpdateDeviceInfo: ((String, String) -> ())?
    var didUpdateEvent: ((EVT, Data) -> ())?
    var didUpdateStep: (() -> ())?
    var didDisconnect: (() -> ())?
    var didGetTime: ((Date) -> ())?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: SBManager.restoreID])
        // init SBServices entities
        let json = Helper.readPlist("SBServices")
        MagicalRecord.save(blockAndWait: { (localContext) in
            SBService.mr_truncateAll(in: localContext)
            if let service = json.dictionary?[Helper.targetName] {
                let entity = SBService.mr_createEntity(in: localContext)
                entity?.name = Helper.targetName
                for (key, value) in service.dictionaryValue {
                    if key == "service" {
                        entity?.service = value.stringValue
                    } else if key == "sender" {
                        entity?.sender = value.stringValue
                    } else if key == "receiver" {
                        entity?.receiver = value.stringValue
                    } else if key == "message" {
                        for (type, offset) in value.dictionaryValue {
                            if let mesageType = MESSAGE_TYPE(rawValue: type) {
                                self.messageOffset[mesageType] = offset.intValue
                            } else {
                                log.error("Unparse dictionary key \(type) in SBServices.plist")
                            }
                        }
                    }
                }
            } else {
                fatalError("Please check SBServices.plist, dictionary with key \(Helper.targetName) missing!")
            }
        })
    }
    
    func reset() {
        centralManager.stopScan()
        if let peripheral = selectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        selectedPeripheral = nil
        //peripherals = [CBPeripheral]()
        writeCharacteristic = [CBPeripheral:CBCharacteristic]()
        didFindDevice = nil
        didPaired = nil
        didPowerOn = nil
        didUpdateValue = nil
        didUpdateDeviceInfo = nil
        didUpdateEvent = nil
        didUpdateStep = nil
        didDisconnect = nil
        didGetTime = nil
    }
    
    // MARK: - Manager action
    
    func updateSelected(peripheral: CBPeripheral) {
        if selectedPeripheral != nil {
            setMessageEnabled(with: [])
        }
        selectedPeripheral = peripheral
    }
    
    func scanAction() {
        if (centralManager.state == .poweredOn) {
            centralManager.stopScan()
            log.debug("begin to scan")
            let services = SBService.serviceArray()
            centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral?, write value: Data) {
        log.info("Writing value: \(value.map { String(format: "%02x", $0) }.joined())")
        if let p = peripheral, let write = writeCharacteristic[p] {
            p.writeValue(value, for: write, type: .withoutResponse)
        }
    }
    
    func selectedDevice(in context: NSManagedObjectContext) -> Device? {
        if let peripheral = SBManager.share.selectedPeripheral {
            return Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: context)
        } else {
            return nil
        }
    }
    
    //MARK: - CBCentralManagerDelegate methods
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let array: [CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in array {
                if peripheral.state == .connected, !peripherals.contains(peripheral) {
                    peripherals.append(peripheral)
                }
            }
        }
        log.debug("Restore state: \(dict)")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log.debug("Power on")
            didPowerOn?()
            // Try to retrieve peripheral from core data
            if let devices = Device.mr_findAll() as? [Device], devices.count > 0 {
                var identifiers = [UUID]()
                for device in devices {
                    if let uuidStr = device.uuid, let uuid = UUID.init(uuidString: uuidStr) {
                        identifiers.append(uuid)
                    }
                }
                let retrieveArray = centralManager.retrievePeripherals(withIdentifiers: identifiers)
                for retrieveP in retrieveArray {
                    if !peripherals.contains(retrieveP) {
                        peripherals.append(retrieveP)
                    }
                }
            }
            // Try to connect to peripherals in background
            self.didPaired = { (peripheral, success, info) in
                if success {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    SBManager.share.updateSelected(peripheral: peripheral)
                    if let current = appDelegate.window?.currentViewController() as? ScanViewController {
                        current.performSegue(withIdentifier: "showWatch", sender: nil)
                    } else {
                        let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                        Helper.makeRootView(controller: tabController, complete: nil)
                    }
                } else {
                    log.error(info ?? "")
                }
            }
            if peripherals.count > 0 {
                for peripheral in peripherals {
                    let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
                    if device != nil && device!.passcode != 0xffff {
                        peripheral.delegate = self
                        central.connect(peripheral, options: nil)
                        //peripheral.discoverServices(nil)
                    } else {
                        // Remove not paired device
                        if let index = peripherals.index(of: peripheral) {
                            peripherals.remove(at: index)
                        }
                    }
                }
            }
            scanAction()
        case .poweredOff:
            log.debug("Power off")
            reset()
            let bluetooth = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BluetoothController")
            Helper.makeRootView(controller: bluetooth, complete: nil)
        default:
            log.debug("Unhandle central manager state: \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log.debug("find peripheral: \(peripheral)")
        log.debug("current peripheral: \(peripherals)")
        if advertisementData.keys.contains(CBAdvertisementDataLocalNameKey), !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
            MagicalRecord.save({ (localContext) in
                var device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                if device == nil {
                    device = Device.mr_createEntity(in: localContext)
                    device?.passcode = 0xffff
                    device?.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
                    device?.nickName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
                    device?.uuid = peripheral.identifier.uuidString
                    device?.notification = Notification.mr_createEntity(in: localContext)
                    if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                        let serviceName = SBService.mr_findFirst(byAttribute: "service", withValue: serviceUUIDs[0].uuidString)?.name
                        device?.serviceName = serviceName
                    } else {
                        device?.serviceName = Helper.targetName
                    }
                } else {
                    if device!.passcode != 0xffff {
                        log.debug("Remember device with passcode: \(device!.passcode)")
                        self.centralManager.stopScan()
                        self.didPaired = { (p, success, info) in
                            if success {
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                SBManager.share.updateSelected(peripheral: peripheral)
                                if let current = appDelegate.window?.currentViewController() as? ScanViewController {
                                    current.performSegue(withIdentifier: "showWatch", sender: nil)
                                } else {
                                    let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                                    Helper.makeRootView(controller: tabController, complete: nil)
                                }
                            } else {
                                log.error(info ?? "")
                            }
                        }
                        peripheral.delegate = self
                        self.centralManager.connect(peripheral, options: nil)
                    }
                }
            }, completion: { (finished, error) in
                self.didFindDevice?(peripheral)
            })
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("did connect \(peripheral)")
        centralManager.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let e = error {
            log.error("central did disconnect to peripheral: \(peripheral.name ?? "") \(e)")
            if peripheral == selectedPeripheral {
                log.debug("try to scan again")
                let scanController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController")
                Helper.makeRootView(controller: scanController, complete: {
                    log.debug("Try to reconnet \(peripheral)")
                    let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
                    if device != nil {
                        if device!.passcode != 0xffff {
                            self.didPaired = { (p, success, info) in
                                if success {
                                    SBManager.share.selectedPeripheral = p
                                    scanController.performSegue(withIdentifier: "showWatch", sender: nil)
                                } else {
                                    log.error(info ?? "")
                                }
                            }
                            peripheral.delegate = self
                            self.centralManager.connect(peripheral, options: nil)
                        }
                    }
                })
            } else {
                log.debug("try to reconnect silently")
                let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
                if device != nil {
                    if device!.passcode != 0xffff {
                        self.didPaired = { (p, success, info) in
                            if !success {
                                log.error(info ?? "")
                            }
                        }
                        peripheral.delegate = self
                        self.centralManager.connect(peripheral, options: nil)
                    }
                }
            }
        } else {
            didDisconnect?()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("central did fail to connect to peripheral: \(peripheral)")
        if let index = peripherals.index(of: peripheral) {
            peripherals.remove(at: index)
        }
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            log.debug("Discover service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service.uuid.uuidString == "180A", let characters = service.characteristics {
            // Device Information
            for character in characters {
                peripheral.readValue(for: character)
            }
        } else if service.uuid.uuidString == "180F", let characters = service.characteristics {
            // Battery
            for character in characters {
                peripheral.readValue(for: character)
                peripheral.setNotifyValue(true, for: character)
            }
         } else if let sb = SBService.mr_findFirst(byAttribute: "service", withValue: service.uuid.uuidString), let characters = service.characteristics {
            for character in characters {
                if character.uuid.uuidString == sb.sender {
                    // Sender
                    peripheral.setNotifyValue(true, for: character)
                } else if character.uuid.uuidString == sb.receiver {
                    // Receiver
                    writeCharacteristic[peripheral] = character
                    // Try to pair device
                    if let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString),
                        device.passcode != 0xffff {
                        pairing(passkey: Int(device.passcode), peripheral: peripheral, complete: { (success, info) in
                            self.didPaired?(peripheral, success, info)
                        })
                    }
                }
            }
        } else {
            log.debug("Ignore service: \(service.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            if let sb = SBService.mr_findFirst(byAttribute: "service", withValue: characteristic.service.uuid.uuidString) {
                if characteristic.uuid.uuidString == sb.sender,
                    let evt = EVT(rawValue: value.toUInt8(from: OFFSET.EVT.EVENT.rawValue)) {
                    switch evt {
                    case .response:
                        if let cmd = CMD(rawValue: value.toUInt8(from: OFFSET.EVT.COMMAND.rawValue)),
                            let status = STATUS(rawValue: value.toUInt8(from: OFFSET.EVT.STATUS.rawValue)) {
                            log.debug("\(cmd) \(status):\(value.map { String(format: "%02x", $0) }.joined())")
                            if status == .success {
                                switch cmd {
                                case .get_time_or_target_step:
                                    if let type = TYPE(rawValue: value.toUInt8(from: OFFSET.EVT.TYPE.rawValue)) {
                                        switch type {
                                        case .time:
                                            var components = DateComponents()
                                            components.year = Int(value.toUInt16(from: OFFSET.EVT.TIME.year.rawValue))
                                            components.month = Int(value.toUInt8(from: OFFSET.EVT.TIME.month.rawValue))
                                            components.day = Int(value.toUInt8(from: OFFSET.EVT.TIME.date.rawValue))
                                            components.hour = Int(value.toUInt8(from: OFFSET.EVT.TIME.hour.rawValue))
                                            components.minute = Int(value.toUInt8(from: OFFSET.EVT.TIME.minute.rawValue))
                                            components.second = Int(value.toUInt8(from: OFFSET.EVT.TIME.second.rawValue))
                                            if let date = Calendar.current.date(from: components) {
                                                didGetTime?(date)
                                            }
                                        case .steps:
                                            let steps = Int(value.toUInt32(from: OFFSET.EVT.TARGET_STEPS.rawValue));
                                            log.debug("Goal:\(steps)")
                                            UserDefaults.set(steps, forKey: .goal)
                                        }
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    case .notify:
                        log.debug("Notify: \(value.map { String(format: "%02x", $0) }.joined())")
                        let type = value.toUInt8(from: OFFSET.NTF.DATA.type.rawValue)
                        if (type == 0) {
                            let year = value.toUInt16(from: OFFSET.NTF.DATA.year.rawValue)
                            let month = value.toUInt8(from: OFFSET.NTF.DATA.month.rawValue)
                            let day = value.toUInt8(from: OFFSET.NTF.DATA.day.rawValue)
                            let steps = UInt32(value.toUInt8(from: OFFSET.NTF.DATA.step_byte0.rawValue)) |
                                UInt32(value.toUInt8(from: OFFSET.NTF.DATA.step_byte1.rawValue)) << 8 |
                                UInt32(value.toUInt8(from: OFFSET.NTF.DATA.step_byte2.rawValue)) << 16
                            
                            MagicalRecord.save({ (localContext) in
                                let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                                let step = Step.mr_createEntity(in: localContext)
                                step?.year = Int16(year)
                                step?.month = Int16(month)
                                step?.day = Int16(day)
                                step?.steps = Int32(steps)
                                step?.date = NSDate()
                                step?.device = device
                            }, completion: { (finish, error) in
                                self.didUpdateStep?()
                                log.debug("\(year)/\(month)/\(day):\(steps)")
                            })
                        } else {
                            log.error("Unhandle notify!\(value.map { String(format: "%02x", $0) }.joined())")
                        }
                    case .find_phone:
                        log.debug("Find phone:\(value.map { String(format: "%02x", $0) }.joined())")
                        self.findPhone()
                    case .emergency:
                        log.debug("Emergency:\(value.map { String(format: "%02x", $0) }.joined())")
                    case .unknown:
                        log.error("Unknown:\(value.map { String(format: "%02x", $0) }.joined())")
                    }
                    self.didUpdateEvent?(evt, value)
                }
            } else {
                MagicalRecord.save({ (localContext) in
                    let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                    if characteristic.service.uuid.uuidString == "180A" {// Device Information
                        let valueStr = String(data: value, encoding: .utf8) ?? "N/A"
                        log.debug("\(characteristic.uuid):\(valueStr)")
                        switch characteristic.uuid.uuidString {
                        case "2A25":// Serial Number String
                            device?.serial = valueStr
                        case "2A26":// Firmware Revision String
                            device?.firmware = valueStr
                        case "2A29":// Manufacturer Name String
                            device?.manufacturer = valueStr
                        case "2A23":// System ID
                            // Only use top 4 bytes as system id
                            device?.system = value.indices.filter { $0 < 4 }.map { String(format: "%02x:", value[$0]) }.joined()
                        default:
                            log.debug("Unhandle Device Information")
                        }
                    } else if characteristic.service.uuid.uuidString == "180F" {// Battery Service
                        log.debug("\(characteristic.uuid):\(Int16(value.toUInt8(from: 0)))")
                        switch characteristic.uuid.uuidString {
                        case "2A19":// Battery Level
                            device?.battery = Int16(value.toUInt8(from: 0))
                        default:
                            log.debug("Unhandle Battery Service")
                        }
                    } else {
                        let valueStr = String.init(data: value, encoding: .utf8) ?? "N/A"
                        log.debug("\(characteristic.uuid):\(valueStr)")
                    }
                }, completion: nil)
            }
            didUpdateValue?(characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            log.error("\(characteristic.uuid) write value error: \(e.localizedDescription)")
        } else {
            log.debug("\(characteristic.uuid) write value success!!!")
        }
    }
}
