//
//  Device+Extennsionnn.swift
//  Taylor
//
//  Created by Kevin Sum on 26/5/2019.
//  Copyright © 2019 KevinSum. All rights reserved.
//

import UIKit

extension Device {
    
    func messageOffset() -> [SBManager.MESSAGE_TYPE:Int] {
        var chars: [Character] = []
        // only get the decimal character in firmware string
        for char in firmware ?? "" {
            if let ascii = char.unicodeScalars.first?.value, ascii >= 48, ascii <= 57 {
                chars.append(char)
            }
        }
        let firmwareVersion = Int(String(chars)) ?? 0
        var maxVersion = 0
        for (version, _) in SBManager.share.messageOffset {
            if version > maxVersion, firmwareVersion >= version {
                maxVersion = version
            }
        }
        return SBManager.share.messageOffset[maxVersion]!
    }

}
