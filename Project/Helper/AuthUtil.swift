//
//  AuthUtil.swift
//  Taylor
//
//  Created by Kevin Sum on 28/5/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

class AuthUtil: NSObject {
    
    static let shared = AuthUtil()
    var token = ""
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

}
