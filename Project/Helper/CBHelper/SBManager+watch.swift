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
    
    enum WatchAsset: String {
        case belt
        case dial
        case hand_hour
        case hand_minute
        case logo
    }
    
    func connect(device: Device) {
        
    }
    
    func getWatchSerial() -> String {
        let watchModel = selectedDevice(in: .mr_default())?.name?.uppercased() ?? ""
        if watchModel.contains("TAYLOR") {
            if watchModel.contains("SW301A") {
                return "301a"
            } else if watchModel.contains("SW301B") {
                return "301b"
            } else if watchModel.contains("SW302") {
                return "302"
            } else if watchModel.contains("SW401") {
                return "401"
            } else if watchModel.contains("SW501") {
                return "501"
            } else if watchModel.contains("SW602") {
                return "602"
            } else {
                return "601_taylor"
            }
        } else if watchModel.contains("FOXTER") {
            return "601_foxter"
        } else if watchModel.contains("SEA-GULL") {
            return "301"
        } else {
            // Defaul model
            return "601_taylor"
        }
    }
    
    func getWatchService() -> String {
        return selectedDevice(in: .mr_default())?.serviceName ?? "TAYLOR"
    }
    
    func getAsset(_ asset: WatchAsset) -> UIImage {
        var name = "", defaultName = ""
        if asset == .logo {
            name = "\(getWatchService())_word"
            defaultName = "TAYLOR_word"
        } else {
            name = "\(getWatchSerial())_\(asset.rawValue)"
            defaultName = "601_taylor_\(asset.rawValue)"
        }
        if let image = UIImage(named: name) {
            return image
        } else {
            return UIImage(named: defaultName)!
        }
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
