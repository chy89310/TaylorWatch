//
//  LoginController.swift
//  Taylor
//
//  Created by Kevin Sum on 23/5/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MBProgressHUD
import UIKit

class LoginController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var _emailLabel: UILabel!
    @IBOutlet weak var _emailTextField: UITextField!
    @IBOutlet weak var _passwordLabel: UILabel!
    @IBOutlet weak var _passwordTextField: UITextField!
    @IBOutlet weak var _registerButton: UIButton!
    @IBOutlet weak var _loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _emailLabel.text = NSLocalizedString("Email", comment: "")
        _passwordLabel.text = NSLocalizedString("Password", comment: "")
        _registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        _loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)
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
            let paramter = ["email": _emailTextField.text!,
                            "password": _passwordTextField.text!]
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            DispatchQueue.global().async {
                ApiHelper.shared.request(
                    name: .login,
                    method: .post,
                    parameters: paramter,
                    success: { (json, response) in
                        DispatchQueue.main.async { hud.hide(animated: true) }
                        if json.dictionary?["status"]?.int == 200 {
                            if let token = json.dictionary?["result"]?.dictionary?["api_token"]?.string {
                                AuthUtil.shared.token = token
                                UserDefaults.set(token, forKey: .token)
                                self.performSegue(withIdentifier: "showWatch", sender: self)
                            } else {
                                self.showAlert(title: "Cannot get token", message: json.description)
                            }
                        } else if let error = json.dictionary?["message"]?.string {
                            self.showAlert(title: NSLocalizedString("Login fail", comment: ""), message: error)
                        }
                },
                    failure: { (error, response) in
                        DispatchQueue.main.async { hud.hide(animated: true) }
                        self.showAlert(title: NSLocalizedString("Login fail", comment: ""), message: error.localizedDescription)
                })
            }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
