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
        if endIndex > startIndex {
            return self[offset...offset].withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt8 in
                return pointer[0]
            })
        } else {
            return 0
        }
    }
    
    func toUInt16(from offset: Data.Index) -> UInt16 {
        if endIndex > startIndex {
            return self[offset...offset+1].withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
                return pointer[0]
            }
        } else {
            return 0
        }
    }
    
    func toUInt32(from offset: Data.Index) -> UInt32 {
        if endIndex > startIndex {
            return self[offset...offset+1].withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
                return pointer[0]
            }
        } else {
            return 0
        }
    }
    
}

extension UserDefaults {
    
    enum UserDefaultKeys: String {
        case birthday
        case email
        case goal
        case height
        case isMale
        case timezone
        case weight
        case target
        case token
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

extension NSLayoutConstraint {
    
    func setMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint.deactivate([self])
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = shouldBeArchived
        newConstraint.identifier = identifier
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
    
}

class Helper: Any {
    
    class var targetName: String {
        get {
            return Bundle.main.infoDictionary?["TargetName"] as? String ?? "TAYLOR"
        }
    }
    
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
    
    class func makeRootView(controller: UIViewController, complete: (() -> ())?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        func navigate() -> () {
            if let root = appDelegate.window?.rootViewController as? UINavigationController {
                log.debug("/**********************************/")
                log.debug("/*Navigate to \(controller.self)*/")
                log.debug("/**********************************/")
                if let tab = controller as? UITabBarController {
                    root.popToRootViewController(animated: false)
                    root.present(tab, animated: true, completion: nil)
                } else {
                    root.viewControllers = [controller]
                    root.popToRootViewController(animated: true)
                }
            } else {
                log.debug("/**********************************/")
                log.debug("/*Force set root to \(controller.self)*/")
                log.debug("/**********************************/")
                appDelegate.window?.rootViewController = controller
            }
        }
        func dismiss(_ controller: UITabBarController, completion: @escaping (() -> ())) -> () {
            log.debug("/**********************************/")
            log.debug("/*Dismiss Current TabBarController*/")
            log.debug("/**********************************/")
            controller.dismiss(animated: true) {
                if let parent = controller.presentedViewController as? UITabBarController {
                    dismiss(parent, completion: completion)
                } else {
                    completion()
                }
            }
        }
        if let current = appDelegate.window?.currentViewController() as? UITabBarController {
            dismiss(current, completion: {
                navigate()
                complete?()
            })
        } else {
            navigate()
            complete?()
        }
    }
    
    class func isValidEmail(_ testStr: String?) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
}
