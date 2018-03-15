//
//  SBManager+enum.swift
//  Taylor
//
//  Created by Kevin Sum on 30/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit

extension SBManager {
    
    enum GATT: String {
        case serial = "Serial Number String"
        case system = "System ID"
        case firmware = "Firmware Revision String"
        case manufacturer = "Manufacturer Name String"
        case battery = "Battery Level"
        case unknown
    }
    
    enum CMD: UInt8 {
        case pair = 0x00
        case set_target_steps = 0x01
        case set_time = 0x02
        case set_message_format = 0x04
        case request_data = 0x05
        case response = 0x06
        case message = 0x07
        case set_hometime = 0x09
        case find_watch = 0x0c
        case get_time_or_target_step = 0x0e
        case unknown
    }
    
    enum STATUS: UInt8 {
        case success = 0x00
        case fail
    }
    
    enum TYPE: UInt8 {
        case time = 0x00
        case steps = 0x01
    }
    
    enum EVT: UInt8 {
        case response = 0x00
        case notify = 0x01
        case find_phone = 0x02
        case emergency = 0x03
        case unknown
    }
    
    enum OFFSET {
        enum EVT: Int {
            case EVENT = 0
            case COMMAND = 1
            case STATUS = 2
            case TYPE = 3
            case TARGET_STEPS = 4
            enum TIME: Int {
                case year = 4
                case month = 6
                case date = 7
                case hour = 8
                case minute = 9
                case second = 10
                case week = 11
            }
        }
        enum NTF: Int {
            case RESPONSE = 1
            case HAS_MORE = 2
            enum DATA: Int {
                case type = 2
                case year = 3
                case month = 5
                case day = 6
                case step_byte0 = 7
                case step_byte1 = 8
                case step_byte2 = 9
            }
        }
    }
    
    enum MESSAGE_TYPE: Int {
        case call
        case sms
        case email
        case qq
        case wechat
        case facebook
        case messenger
        case line
        case skype
        case twitter
        case whatsapp
        case calendar
        case linkedin
    }
    
}
