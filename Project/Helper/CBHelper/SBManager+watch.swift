//
//  SBManager+watch.swift
//  Taylor
//
//  Created by Kevin Sum on 14/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import AVFoundation
import CoreBluetooth
import MagicalRecord
import UIKit
import UserNotifications

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
    
    func findPhone() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: { (granted, error) in
            if granted {
                // Local notification
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Hello I'm here", comment: "")
                let nickName = SBManager.share.selectedDevice(in: .mr_default())?.nickName ?? "TAYLOR"
                content.subtitle = "\(NSLocalizedString("from", comment: "")) \(nickName)"
                content.body = NSLocalizedString("Notification triggered", comment: "")
                let serviceName = SBManager.share.selectedDevice(in: .mr_default())?.serviceName ?? "TAYLOR"
                if let imageURL = Bundle.main.url(forResource: "NOTIFY_\(serviceName)", withExtension: "png") {
                    do {
                        try content.attachments = [UNNotificationAttachment.init(identifier: "image", url: imageURL, options: nil)]
                    } catch let error {
                        log.error(error.localizedDescription)
                    }
                }
                content.sound = UNNotificationSound.default()
                
                let request = UNNotificationRequest(identifier: "notification", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
                    if let e = error {
                        log.error(e)
                    }
                })
            } else {
                // Ask for permission
                let alert = UIAlertController(title: NSLocalizedString("Turn on notification", comment: ""),
                                              message: NSLocalizedString("Please turn on the notification for finding your phone", comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Setting", comment: ""),
                                              style: .default,
                                              handler: { (action) in
                                                if let settingUrl = URL(string: UIApplicationOpenSettingsURLString),
                                                    UIApplication.shared.canOpenURL(settingUrl) {
                                                    UIApplication.shared.open(settingUrl, options: [:], completionHandler: nil)
                                                }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                              style: .cancel,
                                              handler: nil))
                let appDele = UIApplication.shared.delegate as! AppDelegate
                appDele.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        })
        
        guard let url = Bundle.main.url(forResource: "NOTIFY", withExtension: "m4a") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            log.error(error.localizedDescription)
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.play()
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
    
}
