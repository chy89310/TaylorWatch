//
//  Notification+Extension.swift
//  Taylor
//
//  Created by Kevin Sum on 10/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit

extension Notification {
    
    func isTypeOn(_ type: SBManager.MESSAGE_TYPE) -> Bool {
        let flag: [Bool] = [
            isCallOn,
            isSmsOn,
            isEmailOn,
            isQqOn,
            isWechatOn,
            isFacebookOn,
            isMessengerOn,
            isLineOn,
            isSkypeOn,
            isTwitterOn,
            isWhatsappOn,
            isCalendarOn,
            isLinkedinOn
        ]
        return flag[type.rawValue]
    }
    
    func updateStatus(type: SBManager.MESSAGE_TYPE, isOn: Bool) {
        switch type {
        case .call:
            isCallOn = isOn
        case .sms:
            isSmsOn = isOn
        case .email:
            isEmailOn = isOn
        case .qq:
            isQqOn = isOn
        case .wechat:
            isWechatOn = isOn
        case .facebook:
            isFacebookOn = isOn
        case .messenger:
            isMessengerOn = isOn
        case .line:
            isLineOn = isOn
        case .skype:
            isSkypeOn = isOn
        case .twitter:
            isTwitterOn = isOn
        case .whatsapp:
            isWhatsappOn = isOn
        case .calendar:
            isCalendarOn = isOn
        case .linkedin:
            isLinkedinOn = isOn
        }
    }
}
