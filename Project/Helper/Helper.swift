//
//  Helper.swift
//  Project
//
//  Created by Kevin Sum on 13/6/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import Foundation
import SwiftyBeaver
import SwiftyJSON

// Global logger
let log = SwiftyBeaver.self

class Helper: Any {
    
    class var documentDirectory: URL {
        get {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls[urls.endIndex-1]
        }
    }
    
    class func readPlist(_ resource: String) -> JSON {
        if let path = Bundle.main.path(forResource: resource, ofType: "plist") {
            let dict = NSDictionary.init(contentsOfFile: path)
            return JSON.init(dict as Any)
        }
        return JSON.init(Any.self)
    }
    
}
