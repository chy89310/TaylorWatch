//
//  ApiHelper+Define.swift
//  Project
//
//  Created by Kevin Sum on 9/7/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import Foundation

extension ApiHelper {
    
    enum Name: String {
        case baseUrl // baseUrl is required, do not remove
        case version
        case login
        case logout
        case put_user
        case get_user
        case post_user
        case put_device
        case get_devices
        case get_device
        case post_device
        case delete_device
        case put_step
        case post_step
        case forget_password
    }
    
    // Update the defaultEnv if you edit the Env enum
    enum Env: String {
        case prod
        case dev
    }
    
    static internal var defaultEnv: ApiHelper.Env {
        #if DEBUG
            return ApiHelper.Env.dev
        #else
            return ApiHelper.Env.prod
        #endif
    }
    
}
