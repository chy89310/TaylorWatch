//
//  TimeController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 2/12/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
//

import UIKit

class TimeController: BaseViewController {

    @IBOutlet weak var watchFace: WatchFace!
    @IBOutlet weak var phoneSyncBtn: RoundButton!
    @IBOutlet weak var manSyncBtn: RoundButton!
    @IBOutlet weak var timeZoneBtn: RoundButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Localize
        title = NSLocalizedString("TIME", comment: "")
        phoneSyncBtn.setTitle(NSLocalizedString("Phone\nTime", comment: ""), for: .normal)
        manSyncBtn.setTitle(NSLocalizedString("Manual\nSync", comment: ""), for: .normal)
        timeZoneBtn.setTitle(NSLocalizedString("Change\nTime Zone", comment: ""), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        watchFace.updateAsset(withDial: true)
        
        var highlight: RoundButton?
        if UserDefaults.string(of: .timezone) != nil {
            highlight = timeZoneBtn
        }
        highLightButton(highlight)
        SBManager.share.getTime { (date) in
            self.watchFace.setTime(date)
        }
    }
    
    func highLightButton(_ sender: RoundButton?) {
        let buttons = [phoneSyncBtn, manSyncBtn, timeZoneBtn]
        for button in buttons {
            if button == sender {
                button?.focus(true)
            } else {
                button?.focus(false)
            }
        }
    }

    @IBAction func didButtonClick(_ sender: RoundButton) {
        highLightButton(sender)
        if sender != timeZoneBtn {
            NSTimeZone.default = NSTimeZone.system
            UserDefaults.remove(for: .timezone)
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
        let calendar = Calendar.current
        var component = calendar.dateComponents(in: NSTimeZone.default, from: Date())
        if hour > -1 {
            component.hour = hour
        }
        if minute > -1 {
            component.minute = minute
        }
        let date = calendar.date(from: component) ?? Date()
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTimeZone", let timezone = segue.destination as? TimeZoneController {
            timezone.timeController = self
        }
    }
    
}
