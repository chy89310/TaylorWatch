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
    
    // MARK: - Callback methods
    
    var didFindDevice: ((CBPeripheral) -> ())?
    var didFindCharacter: ((CBCharacteristic) -> ())?
    var didPowerOff: (() -> ())?
    var didUpdateValue: ((String) -> ())?
    
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
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
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
        var services = devices[peripheral]?[CBAdvertisementDataServiceUUIDsKey] as! [CBUUID]
//        var serviceIDs = [CBUUID]()
//        for service in services {
//            serviceIDs.append(CBUUID.init(string: service))
//        }
        services.append(contentsOf: [
            CBUUID.init(string: "0x180f"),
            CBUUID.init(string: "0x1800"),
            CBUUID.init(string: "0x180a"),
            CBUUID.init(string: "CDF98BD6-DD14-4B74-9AC2-4F686A3C60A8")])
        peripheral.discoverServices(services)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.error("central did disconnect to peripheral: \(peripheral)")
        discoveredPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("central did fail to connect to peripheral: \(peripheral)")
        discoveredPeripheral = nil
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log.debug("peripheral did discover services: \(String(describing: peripheral.services))")
        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log.debug("peripheral did discover characteristics: \(String(describing: service.characteristics))")
        for character: CBCharacteristic in service.characteristics! {
            characters.append(character)
            didFindCharacter?(character)
//            log.debug("try to subscribe characteristics: \(character)")
//            peripheral.setNotifyValue(true, for: character)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log.debug("peripheral did update for characteristic: \(characteristic)")
        if let value = characteristic.value, let data = String.init(data: value, encoding: .utf8) {
            didUpdateValue?(data)
        }
        
    }
    
}
