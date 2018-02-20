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

extension Collection {
    // Safe index
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Data {
    // Get int value from data with a specific offset
    func toUInt8(from offset: Data.Index) -> UInt8 {
        return self[offset...offset].withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt8 in
            return pointer[0]
        })
    }
    
    func toUInt16(from offset: Data.Index) -> UInt16 {
        return self[offset...offset+1].withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer[0]
        }
    }
    
}

extension UserDefaults {
    
    enum UserDefaultKeys: String {
        case birthday
        case goal
        case height
        case isMale
        case timezone
        case weight
    }
    
    class func string(of key: UserDefaultKeys) -> String? {
        return standard.string(forKey: key.rawValue)
    }
    
    class func int(of key: UserDefaultKeys) -> Int {
        return standard.integer(forKey: key.rawValue)
    }
    
    class func float(of key: UserDefaultKeys) -> Float {
        return standard.float(forKey: key.rawValue)
    }
    
    class func double(of key: UserDefaultKeys) -> Double {
        return standard.double(forKey: key.rawValue)
    }
    
    class func bool(of key: UserDefaultKeys) -> Bool {
        return standard.bool(forKey: key.rawValue)
    }
    
    class func set(_ value: Any?, forKey key: UserDefaultKeys) {
        standard.setValue(value, forKey: key.rawValue)
    }
    
    class func remove(for key: UserDefaultKeys) {
        standard.removeObject(forKey: key.rawValue)
    }
}

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
    
    class func stringToBytes(_ string: String) -> [UInt8] {
        var str = string
        var tic = true
        var bytes = [UInt8]()
        var byte = 0
        if str.characters.count % 2 == 1 {
            // Add 0 at the last 2 bite
            str.characters.insert("0", at: str.characters.index(before: str.characters.endIndex))
        }
        for c in str.characters {
            var d = 0
            switch String(c).lowercased() {
            case "a":
                d = 10
            case "b":
                d = 11
            case "c":
                d = 12
            case "d":
                d = 13
            case "e":
                d = 14
            case "f":
                d = 15
            default:
                d = Int(String(c)) ?? 0
            }
            if tic {
                byte = d*16
            } else {
                byte += d
                bytes.append(UInt8(byte))
            }
            tic = !tic
        }
        return bytes
    }
    
}
