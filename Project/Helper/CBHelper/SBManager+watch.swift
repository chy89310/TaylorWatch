//
//  SBManager+watch.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 14/12/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
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
    
    func subscribeToANCS(_ subscribe: Bool) {
        if subscribe {
            peripheral(selectedPeripheral, write: Data.init(bytes: [0x0d, 0xaa]))
        } else {
            peripheral(selectedPeripheral, write: Data.init(bytes: [0x0d, 0x00]))
        }
    }
    
    func setMessageEnabled(with types:[MESSAGE_TYPE]) {
        var flag = 0;
        if let device = SBManager.share.selectedDevice(in: .mr_default()) {
            let messageOffset = device.messageOffset()
            for type in types {
                if let offSet = messageOffset[type] {
                    flag |= 1 << offSet
                }
            }
        }
        let data = Data.init(bytes:
            [CMD.set_message_format.rawValue,
             UInt8(flag & 0x00ff),
             UInt8((flag >> 8) & 0x00ff),
             UInt8((flag >> 16) & 0x00ff),
             UInt8((flag >> 24) & 0x00ff)])
        peripheral(selectedPeripheral, write: data)
    }
    
    func getTime(complete: @escaping ((Date) -> ())) {
        peripheral(selectedPeripheral,
                   write: Data.init(bytes:
                    [CMD.get_time_or_target_step.rawValue, TYPE.time.rawValue]))
        didGetTime = { (date) in
            complete(date)
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
    
    func getTargetSteps() {
        peripheral(selectedPeripheral,
                   write: Data.init(bytes:
                    [CMD.get_time_or_target_step.rawValue, TYPE.steps.rawValue]))
    }
    
    func setTargetSteps(steps: Int) {
        let data = Data.init(bytes:
            [CMD.set_target_steps.rawValue,
             UInt8(steps & 0xff),
             UInt8(steps >> 8 & 0xff),
             UInt8(steps >> 16 & 0xff),
             UInt8(steps >> 24 & 0xff)])
        peripheral(selectedPeripheral, write: data)
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
        return selectedDevice(in: .mr_default())?.serviceName ?? Helper.targetName
    }
    
    func getAsset(_ asset: WatchAsset) -> UIImage {
        var name = "", defaultName = ""
        if asset == .logo {
            name = "\(getWatchService())_word"
            defaultName = "\(Helper.targetName)_word"
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
    
    func findWatch() {
        let data = Data.init(bytes: [CMD.find_watch.rawValue])
        peripheral(selectedPeripheral, write: data)
    }
    
    func findPhone() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: { (granted, error) in
            if granted {
                // Local notification
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Hello I'm here", comment: "")
                let nickName = SBManager.share.selectedDevice(in: .mr_default())?.nickName ?? Helper.targetName
                content.subtitle = "\(NSLocalizedString("from", comment: "")) \(nickName)"
                content.body = NSLocalizedString("Notification triggered", comment: "")
                //let serviceName = SBManager.share.selectedDevice(in: .mr_default())?.serviceName ?? Helper.targetName
                if let imageURL = Bundle.main.url(forResource: "NOTIFY_\(Helper.targetName)", withExtension: "png") {
                    do {
                        try content.attachments = [UNNotificationAttachment.init(identifier: "image", url: imageURL, options: nil)]
                    } catch let error {
                        log.error(error.localizedDescription)
                    }
                }
                content.sound = UNNotificationSound.default
                
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
                                                if let settingUrl = URL(string: UIApplication.openSettingsURLString),
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
        
        if player?.isPlaying ?? false {
            player?.stop()
        } else {
            guard let url = Bundle.main.url(forResource: "NOTIFY", withExtension: "m4a") else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
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
    
}
