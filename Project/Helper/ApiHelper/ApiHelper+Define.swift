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
