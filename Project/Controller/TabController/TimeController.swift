//
//  TimeController.swift
//  Taylor
//
//  Created by Kevin Sum on 2/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit


class TimeController: BaseViewController {

    @IBOutlet weak var watchFace: WatchFace!
    @IBOutlet weak var phoneSyncBtn: RoundButton!
    @IBOutlet weak var manSyncBtn: RoundButton!
    @IBOutlet weak var timeZoneBtn: RoundButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let date = Date()
        watchFace.setTime(date)
    }

    @IBAction func didButtonClick(_ sender: RoundButton) {
        let buttons = [phoneSyncBtn, manSyncBtn, timeZoneBtn]
        for button in buttons {
            if sender == button {
                button?.focus(true)
            } else {
                button?.focus(false)
            }
        }
        if sender == phoneSyncBtn {
            doPhoneSync(hour: -1, minute: -1)
        }
        if sender == manSyncBtn {
            watchFace.interactable = true
            watchFace.didUpdateTime = { (hour, minute) in
                self.doPhoneSync(hour: hour, minute: minute)
            }
        } else {
            watchFace.interactable = false
            watchFace.didUpdateTime = nil
        }
    }
    
    func doPhoneSync(hour: Int, minute: Int) {
        let calendar = Calendar(identifier: .iso8601)
        var date = Date()
        var component = calendar.dateComponents(in: .current, from: date)
        if hour > -1 {
            component.hour = hour
        }
        if minute > -1 {
            component.minute = minute
        }
        date = calendar.date(from: component) ?? date
        watchFace.setTime(date)
        SBManager.share.setTime(
            year: component.year ?? 2018,
            month: component.month ?? 1,
            day: component.day ?? 1,
            hour: component.hour ?? 0,
            minute: component.minute ?? 0,
            second: component.second ?? 0,
            weekday: component.weekday ?? 0)
    }
    
}
