//
//  RegisterController.swift
//  Taylor
//
//  Created by Kevin Sum on 24/5/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MagicalRecord
import MBProgressHUD
import IQKeyboardManagerSwift
import UIKit

class RegisterController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var _descLabel: UILabel!
    @IBOutlet weak var _emailLabel: UILabel!
    @IBOutlet weak var _emailText: UITextField!
    @IBOutlet weak var _passwordLabel: UILabel!
    @IBOutlet weak var _passwordText: UITextField!
    @IBOutlet weak var _confirmPwdLabel: UILabel!
    @IBOutlet weak var _confirmPwdText: UITextField!
    @IBOutlet weak var _deviceLabel: UILabel!
    @IBOutlet weak var _deviceText: UITextField!
    @IBOutlet weak var _birthDayLabel: UILabel!
    @IBOutlet weak var _birthDayText: UITextField!
    @IBOutlet weak var _weightLabel: UILabel!
    @IBOutlet weak var _weightText: UITextField!
    @IBOutlet weak var _heightLabel: UILabel!
    @IBOutlet weak var _heightText: UITextField!
    @IBOutlet weak var _genderLabel: UILabel!
    @IBOutlet weak var _genderButton: UIButton!
    @IBOutlet weak var _targetLabel: UILabel!
    @IBOutlet weak var _targetText: UITextField!
    @IBOutlet var _datePicker: UIDatePicker!
    @IBOutlet weak var _registerButton: UIButton!
    var didRegistered: ((_ controller: RegisterController) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textAttributes = [NSForegroundColorAttributeName: UIColor("#FDDFC0") ?? .white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        // Localize
        title = NSLocalizedString("PROFILE SETTINGS", comment: "")
        _descLabel.text = NSLocalizedString("Please enter your personal info, the information will be saved on your device.", comment: "")
        _emailLabel.text = NSLocalizedString("Email", comment: "")
        _passwordLabel.text = NSLocalizedString("Password", comment: "")
        _confirmPwdLabel.text = NSLocalizedString("Confirm Password", comment: "")
        _deviceLabel.text = NSLocalizedString("Name Device", comment: "")
        _birthDayLabel.text = NSLocalizedString("Birthday", comment: "")
        _genderLabel.text = NSLocalizedString("Gender", comment: "")
        _weightLabel.text = NSLocalizedString("Weight", comment: "")
        _heightLabel.text = NSLocalizedString("Height", comment: "")
        _targetLabel.text = NSLocalizedString("Target", comment: "")
        _registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        
        _birthDayText.inputView = _datePicker
        // Fix IQKeyboardManager bug
        _datePicker.translatesAutoresizingMaskIntoConstraints = false
        // Initial Info
        _emailText.text = UserDefaults.string(of: .email)
        _deviceText.text = SBManager.share.selectedDevice(in: .mr_default())?.nickName
        _birthDayText.text = UserDefaults.string(of: .birthday)
        let weight = UserDefaults.int(of: .weight)
        _weightText.text = weight > 0 ? String(weight) : ""
        let height = UserDefaults.int(of: .height)
        _heightText.text = height > 0 ? String(height) : ""
        let target = UserDefaults.int(of: .target)
        _targetText.text = target > 0 ? String(target) : ""
        if UserDefaults.bool(of: .isMale) {
            _genderButton.setTitle(NSLocalizedString("Male", comment: ""), for: .normal)
        } else {
            _genderButton.setTitle(NSLocalizedString("Female", comment: ""), for: .normal)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.popToRootViewController(animated: true)
    }
    
    func validate() -> Bool{
        var validate = true
        for text in [_emailText, _deviceText, _birthDayText, _weightText, _heightText, _targetText] {
            if text?.text == "" {
                validate = false
                break
            }
        }
        _emailLabel.textColor = _emailText.text == "" ? .red : .white
        _passwordLabel.textColor = _passwordText.text == "" ? .red : .white
        _confirmPwdLabel.textColor = _confirmPwdText.text == "" ? .red : .white
        _deviceLabel.textColor = _deviceText.text == "" ? .red : .white
        _birthDayLabel.textColor = _birthDayText.text == "" ? .red : .white
        _weightLabel.textColor = _weightText.text == "" ? .red : .white
        _heightLabel.textColor = _heightText.text == "" ? .red : .white
        _targetLabel.textColor = _targetText.text == "" ? .red : .white
        if !Helper.isValidEmail(_emailText.text) {
            validate = false
            _emailLabel.textColor = .red
        }
        if _confirmPwdText.text != _passwordText.text {
            _confirmPwdLabel.textColor = .red
        }
        if let birthDayStr = _birthDayText.text {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.set(formatter.date(from: birthDayStr)?.timeIntervalSince1970, forKey: .birthday)
        }
        if let emailStr = _emailText.text {
            UserDefaults.set(emailStr, forKey: .email)
        }
        if let birthdayStr = _birthDayText.text {
            UserDefaults.set(birthdayStr, forKey: .birthday)
        }
        if let weightStr = _weightText.text {
            UserDefaults.set(Int(weightStr), forKey: .weight)
        }
        if let heightStr = _heightText.text {
            UserDefaults.set(Int(heightStr), forKey: .height)
        }
        if let targetStr = _targetText.text {
            UserDefaults.set(Int(targetStr), forKey: .target)
        }
        UserDefaults.set(isMale(), forKey: .isMale)
        MagicalRecord.save(blockAndWait: { (localContext) in
            if let device = SBManager.share.selectedDevice(in: localContext) {
                device.nickName = self._deviceText.text
            }
        })
        return validate
    }
    
    func isMale() -> Bool {
        return _genderButton.title(for: .normal) == NSLocalizedString("Male", comment: "")
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
    
    @IBAction func didRegisterClick(_ sender: Any) {
        if validate() {
            registerUser()
        }
    }
    
    func registerUser() {
        let parameter: [String: Any] =
            ["email": _emailText.text!,
             "password": _passwordText.text!,
             "gender": isMale(),
             "birthday": _birthDayText.text!,
             "height": _heightText.text!,
             "weight": _weightText.text!,
             "target": _targetText.text!]
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        DispatchQueue.global().async {
            ApiHelper.shared.request(
                name: .put_user,
                method: .put,
                parameters: parameter,
                success: { (json, response) in
                    DispatchQueue.main.async { hud.hide(animated: true) }
                    if json.dictionary?["status"]?.int == 201 {
                        if let token = json.dictionary?["result"]?.dictionary?["api_token"]?.string {
                            AuthUtil.shared.token = token
                            UserDefaults.set(token, forKey: .token)
                            self.didRegistered?(self)
                        } else {
                            self.showAlert(title: "Cannot get token", message: json.description, showDismiss: true)
                        }
                    } else if let error = json.dictionary?["result"]?.dictionary?["error"]?.array?[0].string {
                        self.showAlert(title: NSLocalizedString("Register fail", comment: ""), message: NSLocalizedString(error, comment: ""), showDismiss: true)
                    }
                    log.debug(json)
            },
                failure: { (error, response) in
                    DispatchQueue.main.async { hud.hide(animated: true) }
                    self.showAlert(title: NSLocalizedString("Register fail", comment: ""), message: error.localizedDescription, showDismiss: true)
            })
        }
    }
    
}
