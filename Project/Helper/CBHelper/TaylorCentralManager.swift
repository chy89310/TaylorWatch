//
//  CBCentralManager.swift
//  Project
//
//  Created by Kevin on 22/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth

class TaylorCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Property
    
    static let sharedInstance = TaylorCentralManager()
    var centralManager = CBCentralManager.init(delegate: nil, queue: nil)
    var devices = [CBPeripheral : [String : Any]]()
    var characters = [CBCharacteristic]()
    var discoveredPeripheral: CBPeripheral?
    var serviceID: CBUUID?
    let notiID = CBUUID.init(string: "0001")
    var writeCharacteristic: CBCharacteristic?
    
    // MARK: - Callback methods
    
    var didFindDevice: ((CBPeripheral) -> ())?
    var didFindCharacter: ((CBCharacteristic) -> ())?
    var didPowerOff: (() -> ())?
    var didUpdateValue: ((Data?) -> ())?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    func reset() {
        centralManager.stopScan()
        didUpdateValue = nil
        didPowerOff = nil
        discoveredPeripheral = nil
    }
    
    // MARK: - Manager action
    
    func connectAction() {
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: [CBUUID.init(string: "F638751C-E6D6-4F18-8316-35FFFA696365")], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func peripheral(_ peripheral: CBPeripheral?, write value: Data) {
        log.warning("Writing value: \(value.map { String(format: "%02x", $0) }.joined())")
        
        if let writeCharact = writeCharacteristic {
            if writeCharact.properties.contains(.write) {
                peripheral?.writeValue(value, for: writeCharact, type: .withResponse)
            } else {
                peripheral?.writeValue(value, for: writeCharact, type: .withoutResponse)
            }
        }
    }
    
    //MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log.debug("central did update state: \(central.state)")
        switch central.state {
        case .poweredOn:
            connectAction()
        case .poweredOff:
            didPowerOff?()
            reset()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if advertisementData.keys.contains(CBAdvertisementDataLocalNameKey), !devices.keys.contains(peripheral) {
            log.debug("central did discover peripheral with advertisement: \(advertisementData)")
            devices[peripheral] = advertisementData
            didFindDevice?(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("central did connect to peripheral: \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            log.error("central did disconnect to peripheral: \(peripheral.name ?? "") \(error!.localizedDescription)")
        }
        discoveredPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("central did fail to connect to peripheral: \(peripheral)")
        discoveredPeripheral = nil
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            log.debug("peripheral did discover service: \(service))")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for character: CBCharacteristic in service.characteristics! {
            log.debug("peripheral did discover characteristic: \(character.uuid.uuidString) property: \(character.properties)")
            if !characters.contains(character) {
                characters.append(character)
            }
            if character.properties.contains(.read) {
                log.info("\(character.uuid.uuidString) it is readable!!!")
                peripheral.readValue(for: character)
                
            }
            
            if character.properties.isSuperset(of: [.write, .read]) {
                log.info("\(character.uuid.uuidString) it is read and writable!!!")
                log.verbose(character)
//                writeCharacteristic = character
            }
            if character.properties.contains(.writeWithoutResponse) {
                log.info("\(character.uuid.uuidString) it is writable! without response!!")
                log.verbose(character)
                writeCharacteristic = character
            }
            if character.properties.contains(.notify) {
                log.info("\(character.uuid.uuidString) it is notify!!!")
                peripheral.setNotifyValue(true, for: character)
            }
            didFindCharacter?(character)        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        log.verbose("Service: \(service.uuid.uuidString) included service: \(String(describing: service.includedServices))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        log.info("Character \(characteristic.uuid.description) descriptor: \(String(describing: characteristic.descriptors))")
        for descriptor in characteristic.descriptors! {
            peripheral.readValue(for: descriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            log.info("Characteristic: \(characteristic.uuid.description) value: \(value.map { String(format: "%02x", $0) }.joined())")
        didUpdateValue?(characteristic.value)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        log.warning("Character: \(characteristic.uuid.description) write value success!!!")
    }
}
