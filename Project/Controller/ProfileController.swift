//
//  ProfileController.swift
//  Taylor
//
//  Created by Kevin Sum on 30/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MagicalRecord
import MessageUI
import IQKeyboardManagerSwift
import UIKit

class ProfileController: BaseViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var _emailLabel: UILabel!
    @IBOutlet weak var _emailText: UITextField!
    @IBOutlet weak var _deviceLabel: UILabel!
    @IBOutlet weak var _deviceText: UITextField!
    @IBOutlet weak var _birthDayLabel: UILabel!
    @IBOutlet weak var _birthDayText: UITextField!
    @IBOutlet weak var _weightLabel: UILabel!
    @IBOutlet weak var _weightText: UITextField!
    @IBOutlet weak var _heightLabel: UILabel!
    @IBOutlet weak var _heightText: UITextField!
    @IBOutlet weak var _genderButton: UIButton!
    @IBOutlet var _datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textAttributes = [NSForegroundColorAttributeName: UIColor("#FDDFC0") ?? .white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        title = "PROFILE SETTINGS"
        _deviceText.text = SBManager.share.selectedDevice(in: .mr_default())?.nickName
        _birthDayText.inputView = _datePicker
        // Fix IQKeyboardManager bug
        _datePicker.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func validate() -> Bool{
        var validate = true
        for text in [_emailText, _deviceText, _birthDayText, _weightText, _heightText] {
            if text?.text == "" {
                validate = false
                break
            }
        }
        _emailLabel.textColor = _emailText.text == "" ? .red : .white
        _deviceLabel.textColor = _deviceText.text == "" ? .red : .white
        _birthDayLabel.textColor = _birthDayText.text == "" ? .red : .white
        _weightLabel.textColor = _weightText.text == "" ? .red : .white
        _heightLabel.textColor = _heightText.text == "" ? .red : .white
        if let birthDayStr = _birthDayText.text {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.set(formatter.date(from: birthDayStr)?.timeIntervalSince1970, forKey: .birthday)
        }
        if let weightStr = _weightText.text {
            UserDefaults.set(Int(weightStr), forKey: .weight)
        }
        if let heightStr = _heightText.text {
            UserDefaults.set(Int(heightStr), forKey: .height)
        }
        UserDefaults.set(_genderButton.title(for: .normal) == "Male", forKey: .isMale)
        MagicalRecord.save(blockAndWait: { (localContext) in
            if let device = SBManager.share.selectedDevice(in: localContext) {
                device.name = self._deviceText.text
            }
        })
        return validate
    }

    @IBAction func datePickerDidUpdate(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        _birthDayText.text = formatter.string(from: sender.date)
    }
    
    @IBAction func didGenderClick(_ sender: UIButton) {
        if sender.title(for: .normal) == NSLocalizedString("Male", comment: "") {
            sender.setTitle(NSLocalizedString("Female", comment: ""), for: .normal)
        } else {
            sender.setTitle(NSLocalizedString("Male", comment: ""), for: .normal)
        }
    }
    
    @IBAction func didSkipClick(_ sender: UIButton) {
        performSegue(withIdentifier: "showWatch", sender: nil)
    }
    
    @IBAction func didSaveClick(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail(), validate() {
            let device = SBManager.share.selectedDevice(in: .mr_default())
            let name = device?.name ?? "TAYLOR"
            let nickName = _deviceText.text ?? name
            let serial = device?.serial ?? name
            let bluetooth = device?.system ?? "00:00:00:00:00:00"
            let gender = _genderButton.title(for: .normal) ?? "Male"
            let birthday = _birthDayText.text ?? "2000-01-01"
            let composeVC = MFMailComposeViewController()
            if device?.name == "TAYLOR" {
                composeVC.setToRecipients(["register@taylor-watch.com"])
            } else {
                composeVC.setToRecipients(["newform@foxterwatches.com"])
            }
            composeVC.mailComposeDelegate = self
            composeVC.setSubject("Registration for \(name)")
            composeVC.setMessageBody("Please send out below information to complete the product registration so as to ensure your warranty right and get the lastest product update notification. \n\nDevice Name: \(name) \nDevice Nickname: \(nickName) \nBirthday: \(birthday) \nGender: \(gender) \nSerial: \(serial) \nBluetooth Address: \(bluetooth)", isHTML: false)
            (navigationController ?? self).present(composeVC, animated: true, completion: nil)
        } else if validate() {
            log.info("Not support send mail")
            performSegue(withIdentifier: "showWatch", sender: nil)
        }
    }
    
    // MARK: - MFMailComposeView delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: "showWatch", sender: nil)
        }
    }

}
