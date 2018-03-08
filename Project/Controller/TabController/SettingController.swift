//
//  SettingController.swift
//  Taylor
//
//  Created by Kevin Sum on 3/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import MagicalRecord
import SwiftIconFont
import HexColors
import UIKit

class SettingController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var _notificationSwitch: UISwitch!
    @IBOutlet weak var _collectionView: UICollectionView!
    var messageIcon: [UISwitch:String] = [:]
    var swtichArray: [UISwitch] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _notificationSwitch.layer.cornerRadius = 16
        _notificationSwitch.tintColor = UIColor("#4a4a4a")
        _notificationSwitch.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        updateSwitch()
    }
    
    func updateSwitch() {
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            _notificationSwitch.isOn = device.notification?.isOn ?? true
        }
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
        return SBManager.share.messageMap.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath) as? MessageCell {
            // Status
            if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
                messageCell.isOn = device.notification?.isTypeOn(SBManager.share.messageMap[indexPath.row].type) ?? false
            }
            // Icon image
            if let code = SBManager.share.messageMap[indexPath.row].code as? String {
//                let image = UIImage.icon(from: .FontAwesome,  iconColor: .white, code: code, imageSize: CGSize(width: 30, height: 30), ofSize: 30)
//                messageCell.iconImage.image = image
                messageCell.iconLabel.text = code
                messageCell.iconLabel.parseIcon()
                messageCell.iconImage.isHidden = true
                messageCell.iconLabel.isHidden = false
            } else if let image = SBManager.share.messageMap[indexPath.row].code as? UIImage {
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
                    notification?.updateStatus(type: SBManager.share.messageMap[indexPath.row].type, isOn: isOn)
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
