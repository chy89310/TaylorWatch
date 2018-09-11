//
//  LoginController.swift
//  Taylor
//
//  Created by Kevin Sum on 23/5/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MagicalRecord
import MBProgressHUD
import UIKit

class LoginController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var _emailLabel: UILabel!
    @IBOutlet weak var _emailTextField: UITextField!
    @IBOutlet weak var _passwordLabel: UILabel!
    @IBOutlet weak var _passwordTextField: UITextField!
    @IBOutlet weak var _forgetButton: UIButton!
    @IBOutlet weak var _registerButton: UIButton!
    @IBOutlet weak var _loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _emailLabel.text = NSLocalizedString("Email", comment: "")
        _passwordLabel.text = NSLocalizedString("Password", comment: "")
        _forgetButton.setTitle(NSLocalizedString("forget password", comment: ""), for: .normal)
        _registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        _loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)
        
        // Retrive user info to verify authentication
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        DispatchQueue.global().async {
            AuthUtil.shared.me { (success) in
                DispatchQueue.main.async { hud.hide(animated: true) }
                if success {
                    self.performSegue(withIdentifier: "showWatch", sender: self)
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
            AuthUtil.shared.login(email: _emailTextField.text!, password: _passwordTextField.text!, in: view, complete: { (success, message) in
                if success {
                    self.performSegue(withIdentifier: "showWatch", sender: self)
                } else {
                    self.showAlert(title: NSLocalizedString("Login fail", comment: ""), message: NSLocalizedString(message, comment: ""))
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
        }
    }

}
