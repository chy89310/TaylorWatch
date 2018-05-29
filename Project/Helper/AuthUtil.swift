//
//  AuthUtil.swift
//  Taylor
//
//  Created by Kevin Sum on 28/5/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MagicalRecord
import MBProgressHUD
import UIKit

class AuthUtil: NSObject {
    
    static let shared = AuthUtil()
    var token = UserDefaults.string(of: .token) ?? ""
    var header: [String: String] {
        if let credentialData = "api_token:\(token)".data(using: .utf8) {
            let base64Credentials = credentialData.base64EncodedString()
            return ["Authorization": "Basic \(base64Credentials)"]
        } else {
            return ["":""]
        }
    }
    
    override init() {
        super.init()
    }
    
    func login(email: String, password: String, in view: UIView, complete: @escaping (Bool, String) -> ()) {
        let parameter = ["email": email, "password": password]
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        DispatchQueue.global().async {
            ApiHelper.shared.request(
                name: .login,
                method: .post,
                parameters: parameter,
                success: { (json, response) in
                    DispatchQueue.main.async { hud.hide(animated: true) }
                    if json.dictionary?["status"]?.int == 200 {
                        if let token = json.dictionary?["result"]?.dictionary?["api_token"]?.string {
                            AuthUtil.shared.token = token
                            UserDefaults.set(token, forKey: .token)
                            complete(true, "login success")
                        } else {
                            complete(false, "Cannot get token: \(json.description)")
                        }
                    } else if let error = json.dictionary?["message"]?.string {
                        complete(false, error)
                    } else {
                        complete(false, "Unknown: \(json.description)")
                    }
            },
                failure: { (error, response) in
                    DispatchQueue.main.async { hud.hide(animated: true) }
                    complete(false, error.localizedDescription)
            })
        }
    }
    
    func registerDevice(_ device: Device, _ complete: ((Bool) -> ())?) {
        let parameter: [String: Any] =
            ["bluetoothAddr": device.system ?? "unknown bluetooth addr",
             "deviceName": device.name ?? SBManager.share.getWatchService(),
             "nickName": device.nickName ?? SBManager.share.getWatchService()]
        ApiHelper.shared.request(
            name: .put_device,
            method: .put,
            parameters: parameter,
            headers: AuthUtil.shared.header,
            success: { (json, response) in
                if let id = json.dictionary?["result"]?.dictionary?["id"]?.int16,
                    let uuid = device.uuid {
                    MagicalRecord.save(blockAndWait: { (localContext) in
                        let device = Device.mr_findFirst(byAttribute: "uuid", withValue: uuid, in: localContext)
                        device?.device_id = id
                    })
                    complete?(true)
                } else {
                    complete?(false)
                }
        },
            failure: { (error, response) in
                log.error(error.localizedDescription)
                complete?(false)
        })
        log.debug("Token \(AuthUtil.shared.token)")
    }
    
    func putStep(_ date: Date, _ step: Int32, _ device: Device) {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy-MM-dd";
        let dateStr = dateformat.string(from: date)
        log.debug("put date: \(dateStr), step: \(step)")
        let parameter: [String: Any] =
            ["date": dateStr,
             "step": step]
        ApiHelper.shared.request(
            name: .put_step,
            method: .put,
            parameters: parameter,
            headers: header,
            urlUpdate: { (url) -> (URL) in
                return URL(string: url.absoluteString.replacingOccurrences(of: "$id", with: String(device.device_id))) ?? url
        }, success: { (json, response) in
            log.debug("Put step succes")
        }, failure: { (error, response) in
            log.error(error.localizedDescription);
        })
    }

}
