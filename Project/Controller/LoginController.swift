//
//  LoginController.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 23/5/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import MagicalRecord
import MBProgressHUD
import SwiftyJSON
import UIKit

class LoginController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var _emailLabel: UILabel!
    @IBOutlet weak var _emailTextField: UITextField!
    @IBOutlet weak var _passwordLabel: UILabel!
    @IBOutlet weak var _passwordTextField: UITextField!
    @IBOutlet weak var _forgetButton: UIButton!
    @IBOutlet weak var _registerButton: UIButton!
    @IBOutlet weak var _loginButton: UIButton!
    @IBOutlet weak var _watchFace: WatchFace!
    
    var privacyContent: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _emailLabel.text = NSLocalizedString("Email", comment: "")
        _emailTextField.text = UserDefaults.string(of: .email)
        _passwordLabel.text = NSLocalizedString("Password", comment: "")
        _forgetButton.setTitle(NSLocalizedString("forget password", comment: ""), for: .normal)
        _registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        _loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)
        _watchFace.updateAsset(withDial: true)
        
        // Retrive user info to verify authentication
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        DispatchQueue.global().async {
            AuthUtil.shared.me { (success) in
                if success {
                    self.loginSuccess(success, message: "", hud: hud)
                } else {
                    DispatchQueue.main.async { hud.hide(animated: true) }
                }
            }
        }
    }
    
    func validate() -> Bool{
        var validate = true
        for text in [_passwordTextField, _emailTextField] {
            if text?.text == "" {
                text?.becomeFirstResponder()
                validate = false
                break
            }
        }
        if !Helper.isValidEmail(_emailTextField.text) {
            _emailTextField.becomeFirstResponder()
            validate = false
        }
        _emailLabel.textColor = (_emailTextField.text ?? "" == "" || !Helper.isValidEmail(_emailTextField.text)) ? .red : .white
        _passwordLabel.textColor = _passwordTextField.text == "" ? .red : .white
        return validate
    }

    @IBAction func loginAction(_ sender: Any) {
        if validate() {
            UserDefaults.set(_emailTextField.text, forKey: .email)
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            AuthUtil.shared.login(email: _emailTextField.text!, password: _passwordTextField.text!, in: view, complete: { (success, message) in
                self.loginSuccess(success, message: message, hud: hud)
            })
        }
    }
    
    func loginSuccess(_ success: Bool, message: String, hud: MBProgressHUD) {
        if success {
            ApiHelper.shared.request(name: .get_privacy, method: .get, headers: AuthUtil.shared.header, urlUpdate: { (url) -> (URL) in
                return URL(string: "\(url.absoluteString)/\(NSLocalizedString("locale_code", comment: ""))") ?? url
            }, success: { (json, response) in
                DispatchQueue.main.async { hud.hide(animated: true) }
                let version = UserDefaults.int(of: .privacyVersion)
                if (version < json.dictionary?["result"]?.dictionary?["version"]?.int ?? version+1) {
                    // Need to update privacy version
                    self.privacyContent = json
                    self.performSegue(withIdentifier: "showPrivacy", sender: self)
                } else {
                    self.performSegue(withIdentifier: "showWatch", sender: self)
                }
            }, failure: { (error, response) in
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                    self.performSegue(withIdentifier: "showWatch", sender: self)
                }
            })
        } else {
            DispatchQueue.main.async { hud.hide(animated: true) }
            self.showAlert(title: NSLocalizedString("Login fail", comment: ""), message: NSLocalizedString(message, comment: ""))
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == _passwordTextField {
            textField.resignFirstResponder()
            loginAction(textField)
        } else if textField == _emailTextField {
            _passwordTextField.becomeFirstResponder()
        }
        return true
    }
    
    @IBAction func forgetAction(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("Reset Password", comment: ""), message: "", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = NSLocalizedString("Email", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Send Reset Link", comment: ""), style: .default, handler: { (action) in
            let parameter = ["email": alert.textFields?[0].text ?? ""]
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            DispatchQueue.global().async {
                ApiHelper.shared.request(
                    name: .forget_password,
                    method: .post,
                    parameters: parameter,
                    success: { (json, response) in
                        DispatchQueue.main.async { hud.hide(animated: true) }
                },
                    failure: { (error, response) in
                        DispatchQueue.main.async { hud.hide(animated: true) }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRegister", let register = segue.destination as? RegisterController {
            register.didRegistered = { controller in
                self.showAlert(title: NSLocalizedString("Please login after validate your email address", comment: ""),
                          message: "",
                          showDismiss: false,
                          ok_handler: { (action) in
                            controller.didCancelClick(self)
                })
            }
        } else if segue.identifier == "showPrivacy", let privacy = segue.destination as? PrivacyController {
            privacy.json = privacyContent
        }
    }

}
