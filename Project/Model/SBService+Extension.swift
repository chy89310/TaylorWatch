//
//  SBService+Extension.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 20/2/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import CoreBluetooth
import Foundation

extension SBService {
    
    class func serviceArray() -> [CBUUID] {
        var uuids = [CBUUID]()
        if let services = SBService.mr_findAll() as? [SBService] {
            for service in services {
                if let uuid = service.service?.lowercased() {
                    uuids.append(CBUUID(string: uuid))
                }
            }
        }
        return uuids
    }
    
}
