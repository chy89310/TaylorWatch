//
//  CBPeripheralManager.swift
//  Project
//
//  Created by Kevin on 22/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth

class TaylorPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    
    // MARK: - Property
    
    static let sharedInstance = TaylorPeripheralManager()
    var peripheralManager = CBPeripheralManager.init(delegate: nil, queue: nil)
    let serviceID = CBUUID.init(string: "0000")
    let notiCharacter = CBMutableCharacteristic.init(type: CBUUID.init(string: "0001"), properties: [.notify, .read], value: nil, permissions: .readable)
    
    // MARK: - Callback methods
    
    var didSubscribe: ((Bool, CBCentral) -> ())?
    
    // MARK: - Initialization
    
    override private init() {
        super.init()
        peripheralManager.delegate = self
    }
    
    func reset() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        didSubscribe = nil
    }
    
    // MARK: - Manager action
    
    func advertiseAction() {
        if peripheralManager.state == .poweredOn {
            let service = CBMutableService.init(type: serviceID, primary: true)
            service.characteristics = [notiCharacter]
            peripheralManager.add(service)
        }
    }
    
    //MARK: - CBPeripheralManagerDelegate methods
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        log.debug("peripheral did update state: \(peripheral.state)")
        switch peripheral.state {
        case .poweredOn:
            advertiseAction()
            break
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        log.debug("peripheral did add service: \(service)")
        if let e = error {
            log.error("peripheral add service error \(e)")
        }
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceID]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log.debug("peripheral did start advertising")
        if let e = error {
            log.error("peripheral advertising error \(e)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        log.debug("peripheral did receive write request: \(requests)")
        for request in requests {
            peripheralManager.respond(to: request, withResult: CBATTError.Code.success)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log.debug("peripheral did subscribe from central: \(central)")
        didSubscribe?(true, central)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log.debug("peripheral did unsubscribe from central: \(central)")
        didSubscribe?(false, central)
    }
    
}
