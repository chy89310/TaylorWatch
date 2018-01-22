//
//  SBManager+watch.swift
//  Taylor
//
//  Created by Kevin Sum on 14/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import CoreBluetooth
import UIKit

extension SBManager {
    
    func connect(device: Device) {
        
    }
    
    func pairing(passkey: Int, peripheral: CBPeripheral?, complete: @escaping (_ success: Bool, _ error: String?) -> ()) {
        let data = Data.init(bytes: [CMD.pair.rawValue,UInt8(passkey&0xff),UInt8(passkey>>8&0xff)])
        SBManager.share.didUpdateEvent = { (evt, data) in
            switch evt {
            case .notify:
                SBManager.share.didUpdateEvent = nil
                complete(true, nil)
//            case .response:
//                complete(false, "Response: \(data)")
            default:
                break
            }
        }
        SBManager.share.peripheral(peripheral, write: data)
    }
    
}
