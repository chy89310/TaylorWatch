//
//  Config.swift
//  Project
//
//  Created by Kevin Sum on 13/6/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import Foundation

var isDebug: Bool {
    #if DEBUG
        //uncomment follow to force production environment
        // return false
        return true
    #else
        return false
    #endif
}
