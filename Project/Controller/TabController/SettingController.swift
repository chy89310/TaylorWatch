//
//  SettingController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 3/12/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
//

import MagicalRecord
import SwiftIconFont
import HexColors
import UIKit

class SettingController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var _descLabel: UILabel!
    @IBOutlet weak var _notificationSwitch: UISwitch!
    @IBOutlet weak var _collectionView: UICollectionView!
    @IBOutlet weak var _findButton: UIButton!
    var messageIcon: [UISwitch:String] = [:]
    var swtichArray: [UISwitch] = []
    let messageCode: [SBManager.MESSAGE_TYPE:Any] = [
        .email: "fa:envelope",
        .facebook: "fa:facebook",
        .messenger: #imageLiteral(resourceName: "messenger"),
        .linkedin: "fa:linkedin",
        .call: "fa:phone",
        .twitter: "fa:twitter",
        .line: #imageLiteral(resourceName: "line"),
        .wechat: "fa:weixin",
        .sms: #imageLiteral(resourceName: "text"),
        .qq: "fa:qq",
        .skype: "fa:skype",
        .whatsapp: "fa:whatsapp",
        .calendar: "calendar",
        ]
    let messageTypes = Array(SBManager.share.messageOffset.keys)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localize
        title = NSLocalizedString("SETTINGS", comment: "")
        _descLabel.text = NSLocalizedString("Social Media Notification", comment: "")
        _findButton.setTitle(NSLocalizedString("Find my Watch", comment: ""), for: .normal)
        
        _notificationSwitch.layer.cornerRadius = 16
        _notificationSwitch.tintColor = UIColor("#4a4a4a")
        _notificationSwitch.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        updateSwitch()
    }
    
    func updateSwitch() {
        var enabledTypes: [SBManager.MESSAGE_TYPE] = []
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            _notificationSwitch.isOn = device.notification?.isOn ?? true
            for (type, _) in SBManager.share.messageOffset {
                if device.notification?.isTypeOn(type) ?? false {
                    enabledTypes.append(type)
                }
            }
        }
        SBManager.share.setMessageEnabled(with: _notificationSwitch.isOn ? enabledTypes : [])
        UIView.animate(withDuration: 0.2) {
            self._collectionView.alpha = self._notificationSwitch.isOn ? 1.0 : 0.0
            self._collectionView.isHidden = !self._notificationSwitch.isOn
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
                }
                notification?.device = device
            }
        }) { (finish, error) in
            self.updateSwitch()
        }
    }
    
    @IBAction func didFindWatchClick(_ sender: UIButton) {
        SBManager.share.findWatch()
    }
    // Mark: - UICollectionView datasource and delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath) as? MessageCell {
            // Status
            if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
                messageCell.isOn = device.notification?.isTypeOn(messageTypes[indexPath.row]) ?? false
            }
            // Icon image
            if let code = messageCode[messageTypes[indexPath.row]] as? String {
                messageCell.iconLabel.text = code
                messageCell.iconLabel.parseIcon()
                messageCell.iconImage.isHidden = true
                messageCell.iconLabel.isHidden = false
            } else if let image = messageCode[messageTypes[indexPath.row]] as? UIImage {
                messageCell.iconImage.image = image
                messageCell.iconImage.isHidden = false
                messageCell.iconLabel.isHidden = true
            }
            return messageCell
        } else {
            return MessageCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let messageCell = collectionView.cellForItem(at: indexPath) as? MessageCell {
            let isOn = !messageCell.isOn
            MagicalRecord.save({ (localContext) in
                if let device = SBManager.share.selectedDevice(in: localContext) {
                    var notification = device.notification
                    if notification == nil {
                        notification = Notification.mr_createEntity(in: localContext)
                    }
                    notification?.updateStatus(type: self.messageTypes[indexPath.row], isOn: isOn)
                    notification?.device = device
                }
            }) { (finish, error) in
                self.updateSwitch()
                collectionView.reloadData()
            }
        }
    }
    
}

@IBDesignable
class MessageCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    var isOn = false {
        didSet {
            if isOn {
                self.backgroundColor = UIColor("#fddfc0")
            } else {
                self.backgroundColor = .clear
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = rect.width/2
        layer.masksToBounds = true
    }
    
    
}
