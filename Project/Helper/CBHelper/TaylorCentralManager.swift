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
    var discoveredPeripheral: CBPeripheral?
    let serviceID = CBUUID.init(string: "0000")
    let notiID = CBUUID.init(string: "0001")
    
    // MARK: - Callback methods
    
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
        centralManager.scanForPeripherals(withServices: [CBUUID.init(string: "0000")], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
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
        if let serviceIDArray = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            if serviceIDArray[0].uuidString == "0000" {
                discoveredPeripheral = peripheral
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("central did connect to peripheral: \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.debug("central did disconnect to peripheral: \(peripheral)")
        discoveredPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.debug("central did fail to connect to peripheral: \(peripheral)")
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
            log.debug("try to subscribe characteristics: \(character)")
            peripheral.setNotifyValue(true, for: character)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log.debug("peripheral did update for characteristic: \(characteristic)")
        if let value = characteristic.value, let data = String.init(data: value, encoding: .utf8) {
            didUpdateValue?(data)
        }
        
    }
    
}
