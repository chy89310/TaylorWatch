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
        let flag: [SBManager.MESSAGE_TYPE:Bool] = [
            .call:isCallOn,
            .sms:isSmsOn,
            .email:isEmailOn,
            .qq:isQqOn,
            .wechat:isWechatOn,
            .facebook:isFacebookOn,
            .messenger:isMessengerOn,
            .line:isLineOn,
            .skype:isSkypeOn,
            .twitter:isTwitterOn,
            .whatsapp:isWhatsappOn,
            .calendar:isCalendarOn,
            .linkedin:isLinkedinOn
        ]
        return flag[type] ?? false
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
