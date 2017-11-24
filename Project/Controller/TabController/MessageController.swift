//
//  MessageController.swift
//  Taylor
//
//  Created by Kevin Sum on 3/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import MagicalRecord
import UIKit

class MessageController: BaseViewController {

    @IBOutlet weak var _notificationSwitch: UISwitch!
    @IBOutlet weak var _callSwitch: UISwitch!
    @IBOutlet weak var _messageSwitch: UISwitch!
    @IBOutlet weak var _mailSwitch: UISwitch!
    @IBOutlet weak var _qqSwitch: UISwitch!
    @IBOutlet weak var _wechatSwitch: UISwitch!
    @IBOutlet weak var _facebookSwitch: UISwitch!
    @IBOutlet weak var _messagerSwitch: UISwitch!
    @IBOutlet weak var _lineSwitch: UISwitch!
    @IBOutlet weak var _skypeSwitch: UISwitch!
    @IBOutlet weak var _twitterSwitch: UISwitch!
    @IBOutlet weak var _whatsappSwitch: UISwitch!
    @IBOutlet weak var _calendarSwitch: UISwitch!
    @IBOutlet weak var _linkedInSwitch: UISwitch!
    var switchControl: [UISwitch:SBManager.MESSAGE_TYPE] = [:]
    var swtichArray: [UISwitch] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switchControl = [
            _callSwitch: .call,
            _messageSwitch: .sms,
            _mailSwitch: .email,
            _qqSwitch: .qq,
            _wechatSwitch: .wechat,
            _facebookSwitch: .facebook,
            _messagerSwitch: .messenger,
            _lineSwitch: .line,
            _skypeSwitch: .skype,
            _twitterSwitch: .twitter,
            _whatsappSwitch: .whatsapp,
            _calendarSwitch: .calendar,
            _linkedInSwitch: .linkedin
        ]
        updateSwitch()
        
    }
    
    func updateSwitch() {
        let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) ?? Device()
        _notificationSwitch.isOn = device.notification?.isOn ?? false
        var enabledTypes: [SBManager.MESSAGE_TYPE] = []
        for uiSwitch in Array(switchControl.keys) {
            uiSwitch.isOn = device.notification?.isTypeOn(switchControl[uiSwitch]!) ?? false
            uiSwitch.isEnabled = _notificationSwitch.isOn
            if (uiSwitch.isOn) {
                enabledTypes.append(switchControl[uiSwitch]!)
            }
        }
        if _notificationSwitch.isOn {
            SBManager.share.setMessageEnabled(with: enabledTypes)
        } else {
            SBManager.share.setMessageEnabled(with: [])
        }
    }
    
    @IBAction func didSwitchUpdate(_ sender: UISwitch) {
        let isOn = sender.isOn
        MagicalRecord.save({ (localContext) in
            if let device = SBManager.share.selectedDevice(in: localContext) {
                var notification = device.notification
                if notification == nil {
                    notification = Notification.mr_createEntity(in: localContext)
                }
                if sender == self._notificationSwitch {
                    notification?.isOn = isOn
                } else {
                    notification?.updateStatus(type: self.switchControl[sender]!, isOn: isOn)
                }
                notification?.device = device
            }
        }) { (fnish, error) in
            self.updateSwitch()
        }
        //            SBManager.share.setMessageEnabled(with: [.call,.sms])
        //        } else {
        //            SBManager.share.setMessageEnabled(with: [])
        //        }
    }
    
}
