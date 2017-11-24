//
//  SBPeripheral.swift
//  Taylor
//
//  Created by Kevin Sum on 22/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import CoreBluetooth
import UIKit



class SBPeripheral: NSObject, CBPeripheralManagerDelegate {
    
    static let share = SBPeripheral()
    static let SERVICE_UUID_STRING = "C00ED14C-1166-415E-9075-51989B9A6EC6"
    var manager = CBPeripheralManager.init(delegate: nil, queue: nil)
    var isReady = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func broadcasting() {
        if manager.state == .poweredOn {
            log.debug("Start broadcasting!")
            let service = CBMutableService.init(type: CBUUID.init(string: SBPeripheral.SERVICE_UUID_STRING), primary: true)
            manager.removeAllServices()
            manager.add(service)
        }
        isReady = true
    }
    
    func stop() {
        manager.stopAdvertising()
        isReady = false
    }
    
    // MARK: - Peripheral manager delegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            broadcasting()
        default:
            manager.stopAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        log.debug("Start advertising")
        manager.startAdvertising(nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log.debug("Did subscribe by: \(central) to: \(characteristic)")
    }

}
