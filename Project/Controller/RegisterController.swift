//
//  RegisterController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 24/5/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import MagicalRecord
import MBProgressHUD
import IQKeyboardManagerSwift
import UIKit

class RegisterController: BaseViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
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
    @IBOutlet var _goalPicker: UIPickerView!
    @IBOutlet var _datePicker: UIDatePicker!
    @IBOutlet weak var _cancelButton: UIButton!
    @IBOutlet weak var _registerButton: UIButton!
    var didRegistered: ((_ controller: RegisterController) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localize
        title = NSLocalizedString("Registration by email", comment: "")
        _descLabel.text = ""
        _emailLabel.text = NSLocalizedString("Email", comment: "")
        _passwordLabel.text = NSLocalizedString("Password", comment: "")
        _confirmPwdLabel.text = NSLocalizedString("Confirm Password", comment: "")
        _deviceLabel.text = NSLocalizedString("Name Device", comment: "")
        _birthDayLabel.text = NSLocalizedString("Birthday", comment: "")
        _genderLabel.text = NSLocalizedString("Gender", comment: "")
        _weightLabel.text = NSLocalizedString("Weight", comment: "")
        _heightLabel.text = NSLocalizedString("Height", comment: "")
        _targetLabel.text = NSLocalizedString("Goals", comment: "")
        _registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        _cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        
        _birthDayText.inputView = _datePicker
        _targetText.inputView = _goalPicker
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
        let target = UserDefaults.int(of: .goal)
        _targetText.text = target > 0 ? String(target) : ""
        _goalPicker.selectRow(HealthOptions.rowForGoal(UserDefaults.int(of: .goal)), inComponent: 0, animated: false)
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
            validate = false
            _confirmPwdLabel.textColor = .red
        }
        if let birthDayStr = _birthDayText.text {
            UserDefaults.set(Helper.dateFormatter().date(from: birthDayStr)?.timeIntervalSince1970, forKey: .birthday)
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
            UserDefaults.set(Int(targetStr), forKey: .goal)
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
        _birthDayText.text = Helper.dateFormatter().string(from: sender.date)
    }
    
    @IBAction func didGenderClick(_ sender: UIButton) {
        if sender.title(for: .normal) == NSLocalizedString("Male", comment: "") {
            sender.setTitle(NSLocalizedString("Female", comment: ""), for: .normal)
        } else {
            sender.setTitle(NSLocalizedString("Male", comment: ""), for: .normal)
        }
    }
    
    @IBAction func didCancelClick(_ sender: Any) {
        if let navigate = navigationController {
            navigate.popViewController(animated: true)
        }  else {
            dismiss(animated: true, completion: nil)
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
                        self.didRegistered?(self)
                    } else if let error = json.dictionary?["result"]?.dictionary?["error"]?.array?[0].string {
                        self.showAlert(title: NSLocalizedString("Register fail", comment: ""), message: NSLocalizedString(error, comment: ""), showDismiss: true)
                    } else {
                        self.showAlert(title: NSLocalizedString("Register fail", comment: ""), message: "")
                    }
                    log.debug(json)
            },
                failure: { (error, response) in
                    DispatchQueue.main.async { hud.hide(animated: true) }
                    self.showAlert(title: NSLocalizedString("Register fail", comment: ""), message: error.localizedDescription, showDismiss: true)
            })
        }
    }
    
    // MARK: - UIPickerView datasource and delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return HealthOptions.numberOfGoals()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = String(HealthOptions.goalForRow(row))
        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        _targetText.text = String(HealthOptions.goalForRow(row))
    }
    
}
