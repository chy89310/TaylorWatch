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
            AuthUtil.shared.login(email: _emailTextField.text!, password: _passwordTextField.text!, in: view, complete: { (success, message) in
                if success {
                    self.performSegue(withIdentifier: "showWatch", sender: self)
                } else {
                    self.showAlert(title: NSLocalizedString("Login fail", comment: ""), message: message)
                }
            })
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRegister", let register = segue.destination as? RegisterController {
            register.didRegistered = { controller in
                controller.performSegue(withIdentifier: "showWatch", sender: self)
            }
        }
    }

}
