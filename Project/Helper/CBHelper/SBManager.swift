//
//  SBManager.swift
//  Project
//
//  Created by Kevin on 22/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import MagicalRecord
import UIKit
import CoreBluetooth

class SBManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Property

    static let share = SBManager()
    static let restoreID = "tayler.central.id"
    var centralManager = CBCentralManager.init(delegate: nil, queue: nil)
    var peripherals = [CBPeripheral]()
    var restoreServices = [CBUUID]()
    var selectedPeripheral: CBPeripheral?
    var serviceID: CBUUID?
    let notiID = CBUUID.init(string: "0001")
    var deviceInfo = [String: String]()
    var writeCharacteristic: CBCharacteristic?
    var readyToScan = false
    
    // MARK: - Callback methods
    
    var didFindDevice: ((CBPeripheral) -> ())?
    var didFindCharacter: ((CBCharacteristic) -> ())?
    var didPowerOff: (() -> ())?
    var didUpdateValue: ((CBCharacteristic) -> ())?
    var didUpdateDeviceInfo: ((String, String) -> ())?
    var didUpdateEvent: ((EVT, Data) -> ())?
    var didUpdateStep: (() -> ())?
    var didDisconnect: (() -> ())?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
//        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: SBManager.restoreID])
    }
    
    func reset() {
        centralManager.stopScan()
        if let peripheral = selectedPeripheral, peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        selectedPeripheral = nil
        peripherals = [CBPeripheral]()
        didFindDevice = nil
        didFindCharacter = nil
        didPowerOff = nil
        didUpdateValue = nil
        didUpdateDeviceInfo = nil
        didUpdateEvent = nil
        didUpdateStep = nil
    }
    
    // MARK: - Manager action
    
    func connectAction() {
        if (centralManager.state == .poweredOn) {
            centralManager.stopScan()
            log.debug("begin to scan")
            //        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            let services = restoreServices.count > 0 ? restoreServices : [CBUUID.init(string: "F638751C-E6D6-4F18-8316-35FFFA696365"),CBUUID.init(string: "BCEB338A-E422-93D9-BA1D-8B50DEF2CF7B")]
            centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            readyToScan = true
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral?, write value: Data) {
        log.info("Writing value: \(value.map { String(format: "%02x", $0) }.joined())")
        
        if let writeCharact = writeCharacteristic {
//            if writeCharact.properties.contains(.write) {
//                peripheral?.writeValue(value, for: writeCharact, type: .withResponse)
//            } else {
                peripheral?.writeValue(value, for: writeCharact, type: .withoutResponse)
//            }
        }
    }
    
    func selectedDevice(in context: NSManagedObjectContext) -> Device? {
        if let peripheral = SBManager.share.selectedPeripheral {
            return Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: context)
        } else {
            return nil
        }
    }
    
    func setTime(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, weekday: Int) {
        let data = Data.init(bytes:
            [CMD.set_time.rawValue,
             UInt8(year & 0xff),
             UInt8(year >> 8 & 0xff),
             UInt8(month),
             UInt8(day),
             UInt8(hour),
             UInt8(minute),
             UInt8(second),
             UInt8(weekday)])
        peripheral(selectedPeripheral, write: data)
    }
    
    func setMessageEnabled(with types:[MESSAGE_TYPE]) {
        var flag = 0;
        for type in types {
            flag |= 1 << type.rawValue
        }
        let data = Data.init(bytes:
            [CMD.set_message_format.rawValue,
             UInt8(flag & 0x00ff),
             UInt8((flag >> 8) & 0x00ff),
             UInt8((flag >> 16) & 0x00ff),
             UInt8((flag >> 24) & 0x00ff)])
        peripheral(selectedPeripheral, write: data)
    }
    
    //MARK: - CBCentralManagerDelegate methods
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let array: [CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in array {
                peripherals.append(peripheral)
//                switch peripheral.state {
//                case .connected:
//                    peripherals.append(peripheral)
//                default:
//                    log.debug("Restore peripheral didn't connected, do nothing, maybe?")
//                }
            }
        }
        if let array: [CBUUID] = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            restoreServices = array
        }
        log.debug("Restore central manger: \(central)")
        log.debug("Restore state: \(dict)")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log.debug("Power on")
            if peripherals.count > 0 {
                centralManager.stopScan()
                for peripheral in peripherals {
                    central.connect(peripheral, options: nil)
                    peripheral.delegate = self
                    peripheral.discoverServices(nil)
                    let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
                    if device != nil && device!.passcode != 0xffff {
                        self.didFindCharacter = { (characteristic) in
                            if characteristic.properties.rawValue == 4 {
                                self.pairing(
                                    passkey: Int(device!.passcode),
                                    peripheral: peripheral,
                                    complete: { (success, info) in
                                        if success {
                                            log.debug("Make root view with tab controller")
                                            SBManager.share.selectedPeripheral = peripheral
                                            let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            appDelegate.window?.rootViewController = tabController
                                        }
                                })
                            }
                        }
                    }
                }
            } else if let devices = Device.mr_findAll() as? [Device], devices.count > 0 {
                var identifiers = [UUID]()
                for device in devices {
                    if let uuidStr = device.uuid, let uuid = UUID.init(uuidString: uuidStr) {
                        identifiers.append(uuid)
                    }
                }
                let retrieveArray = centralManager.retrievePeripherals(withIdentifiers: identifiers)
                if retrieveArray.count > 0 {
                    log.debug("Retrive peripherals: \(retrieveArray)")
                    centralManager.stopScan()
                    for peripheral in retrieveArray {
                        peripherals.append(peripheral)
                        if Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)?.passcode == 0xffff {
                            didFindDevice?(peripheral)
                        } else {
                            peripheral.delegate = self
                            peripheral.discoverServices(nil)
                            centralManager.connect(peripheral, options: nil)
                            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
                            if device != nil && device!.passcode != 0xffff {
                                self.didFindCharacter = { (characteristic) in
                                    if characteristic.properties.rawValue == 4 {
                                        self.pairing(
                                            passkey: Int(device!.passcode),
                                            peripheral: peripheral,
                                            complete: { (success, info) in
                                                if success {
                                                    log.debug("Make root view with tab controller")
                                                    SBManager.share.didUpdateEvent = nil
                                                    SBManager.share.selectedPeripheral = peripheral
                                                    let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                                                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                                    appDelegate.window?.rootViewController = tabController
                                                } else {
                                                    log.error(info)
                                                }
                                        })
                                    }
                                }
                            }
                        }
                    }
                } else {
                    connectAction()
                }
            } else {
                connectAction()
            }
        case .poweredOff:
            log.debug("Power off")
            didPowerOff?()
            reset()
        default:
            break
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
                    device?.uuid = peripheral.identifier.uuidString
                    device?.notification = Notification.mr_createEntity(in: localContext)
                } else {
                    if device!.passcode != 0xffff {
                        self.centralManager.stopScan()
                        self.centralManager.connect(peripheral, options: nil)
                        log.debug("Remember device with passcode: \(device!.passcode)")
                        self.didFindCharacter = { (characteristic) in
                            if characteristic.properties.rawValue == 4 {
                                self.pairing(
                                    passkey: Int(device!.passcode),
                                    peripheral: peripheral,
                                    complete: { (success, info) in
                                        if success {
                                            log.debug("Make root view with tab controller")
                                            SBManager.share.selectedPeripheral = peripheral
                                            let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            appDelegate.window?.rootViewController = tabController
                                        } else {
                                            log.error(info)
                                        }
                                })
                            }
                        }
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
            log.error("central did disconnect to peripheral: \(peripheral.name ?? "") \(e.localizedDescription)")
//            connectAction()
            log.debug("try to scan again")
            log.debug("Make root view with scan controller")
            let scanController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = scanController
            log.debug("Try to reconnet \(peripheral)")
            let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString)
            if device != nil {
                if device!.passcode != 0xffff {
                    self.centralManager.connect(peripheral, options: nil)
                    SBManager.share.didFindCharacter = { (characteristic) in
                        if characteristic.properties.rawValue == 4 {
                            self.pairing(
                                passkey: Int(device!.passcode),
                                peripheral: peripheral,
                                complete: { (success, info) in
                                    if success {
                                        log.debug("Make root view with tab controller")
                                        SBManager.share.selectedPeripheral = peripheral
                                        let tabController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabController")
                                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                        appDelegate.window?.rootViewController = tabController
                                    } else {
                                        log.error(info)
                                    }
                            })
                        }
                    }
                }
            }
        } else {
            didDisconnect?()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("central did fail to connect to peripheral: \(peripheral)")
        reset()
//        connectAction()
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for character: CBCharacteristic in service.characteristics! {
            log.debug("\nCharacteristic: \(character.uuid.uuidString) property: \(character.properties)")
            switch character.uuid.uuidString {
            case "2A25":
                log.debug("DEVICE_INFO_SERIAL_NUMBER")
                peripheral.readValue(for: character)
            case "2A26":
                log.debug("DEVICE_INFO_FIRMWARE_REVISION")
                peripheral.readValue(for: character)
            case "2A29":
                log.debug("DEVICE_INFO_MANUFACTURER_NAME")
                peripheral.readValue(for: character)
            case "2A19":
                log.debug("BATTERY_SERVICE")
                peripheral.readValue(for: character)
            case "2A23":
                log.debug("DEVICE_INFO_SYSTEM")
                peripheral.readValue(for: character)
            default:
                log.debug("Unread character")
            }
            
            if character.properties.contains(.read) {
//                peripheral.readValue(for: character)
                
            }
            
            if character.properties.rawValue == 4 {
                log.debug("\nWrite characteristic: \(character.uuid.uuidString)")
                writeCharacteristic = character
            }
            if character.properties.rawValue == 16 {
                peripheral.setNotifyValue(true, for: character)
            }
            didFindCharacter?(character)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            MagicalRecord.save({ (localContext) in
                let device = Device.mr_findFirst(byAttribute: "uuid", withValue: peripheral.identifier.uuidString, in: localContext)
                let valueStr = String.init(data: value, encoding: .utf8) ?? "N/A"
                switch characteristic.uuid.uuidString {
                case "2A25":
                    device?.serial = valueStr
                case "2A26":
                    device?.firmware = valueStr
                case "2A29":
                    device?.manufacturer = valueStr
                case "2A19":
                    device?.battery = Int16(value.toUInt8(from: 0))
                case "2A23":
                    device?.system = value.map { String(format: "%02x", $0) }.joined()
                default:
                    break
                }
            }, completion: nil)
            
            if characteristic.isNotifying {
                if let value = characteristic.value, let evt = EVT(rawValue: value.toUInt8(from: OFFSET.EVT.EVENT.rawValue)) {
                    switch evt {
                    case .response:
                        log.debug("Response:\(characteristic)")
                    case .notify:
                        log.debug("Notify: \(value.map { String(format: "%02x", $0) }.joined()) \(characteristic))")
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
                            log.error("Unhandle notify!")
                        }
                    case .find_phone:
                        log.debug("Find phone:")
                    case .emergency:
                        log.debug("Emergency:")
                    case .unknown:
                        log.error("Unknown:")
                    }
                    didUpdateEvent?(evt, value)
                }
            }
            didUpdateValue?(characteristic)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        log.debug("Character: \(characteristic.uuid.description) write value success!!!")
    }
}
