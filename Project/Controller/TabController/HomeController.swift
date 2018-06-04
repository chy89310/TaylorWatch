//
//  HomeController.swift
//  Taylor
//
//  Created by Kevin Sum on 19/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import HexColors
import MagicalRecord
import UIKit

class HomeController: BaseViewController {

    @IBOutlet weak var watchView: WatchView!
    @IBOutlet weak var deviceButton: RoundButton!
    @IBOutlet weak var stepView: StepPercentView!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    var interval: TimeInterval = 0
    let appDele = UIApplication.shared.delegate as! AppDelegate
    var networkReachable: Bool {
        return appDele.reach?.isReachable() ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localize
        title = NSLocalizedString("HOME", comment: "")
        deviceButton.setTitle(NSLocalizedString("Device Options", comment: ""), for: .normal)
        
        // Update ANCS notification
        SBManager.share.subscribeToANCS(true)
        var enabledTypes: [SBManager.MESSAGE_TYPE] = []
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            for type in Array(SBManager.share.messageOffset.keys) {
                if device.notification?.isTypeOn(type) ?? false {
                    enabledTypes.append(type)
                }
            }
            SBManager.share.setMessageEnabled(with: (device.notification?.isOn ?? true) ? enabledTypes : [])
            
            // Try to register the device once to verify the authentication
            if networkReachable {
                AuthUtil.shared.registerDevice(device, { (success) in
                    if !success {
                        self.promptLogin(message: nil)
                    }
                })
            }
        }
        
        // Get target steps
        SBManager.share.getTargetSteps()
        
        SBManager.share.didUpdateStep = {
            self.updateView()
            if self.networkReachable,
                let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
                let step = Step.step(for: Date())
                AuthUtil.shared.putStep(Date(), step, device)
            }
        }
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Get watch time
        SBManager.share.getTime { (date) in
            self.interval = date.timeIntervalSinceNow
            self.updateView()
        }
    }
    
    func updateView() {
        watchView.updateAsset(withDial: false)
        
        let date = Date(timeIntervalSinceNow: interval)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "dd MMM"
        dateLabel.text = formatter.string(from: date)
        formatter.dateFormat = "EEEE"
        weekDayLabel.text = formatter.string(from: date)
        watchView.watchFace.setTime(date)
        let step = Step.step(for: Date())
        drawStepPercent(step: step)
        self.stepLabel.text = "\(step) \(NSLocalizedString("STEPS", comment: ""))"
        let cals = Int(CBUtils.caloriesFrom(step: Int(step)))
        self.caloriesLabel.text = "\(cals) \(NSLocalizedString("CALS", comment: ""))"
    }
    
    func drawStepPercent(step: Int32) {
        var goal = UserDefaults.int(of: .goal)
        if goal == 0 {
            // Set default goal
            goal = 10000
            UserDefaults.set(goal, forKey: .goal)
        }
        stepView.percent = CGFloat(step)/CGFloat(goal)
        stepView.setNeedsDisplay()
    }
    
    func promptLogin(message: String?) {
        let alert = UIAlertController(title: NSLocalizedString("Please login", comment: ""), message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (text) in
            text.placeholder = NSLocalizedString("Email", comment: "")
            text.textContentType = .emailAddress
            text.keyboardType = .emailAddress
        })
        alert.addTextField(configurationHandler: { (text) in
            text.placeholder = NSLocalizedString("Password", comment: "")
            if #available(iOS 11.0, *) {
                text.textContentType = .password
            }
            text.isSecureTextEntry = true
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default, handler: { (action) in
            let email = alert.textFields![0].text ?? ""
            let password = alert.textFields![1].text ?? ""
            if email.count > 0 && password.count > 0 {
                AuthUtil.shared.login(email: email, password: password, in: self.view, complete: { (success, message) in
                    if success {
                        // Try to register device again
                        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
                            AuthUtil.shared.registerDevice(device, nil)
                        }
                    } else { self.promptLogin(message: message) }
                })
            } else {
                self.promptLogin(message: NSLocalizedString("please input email and password", comment: ""))
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Register", comment: ""), style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "showRegister", sender: self)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRegister", let register = segue.destination as? RegisterController {
            register.didRegistered = { controller in
                controller.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

class StepPercentView: RoundView {
    
    @IBInspectable var percent: CGFloat = 1.0
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if (percent < 0) {
            percent = 0
        } else if (percent > 1) {
            percent = 1
        }
        UIColor("#FDDFC0")?.set()
        let center = CGPoint(x: rect.size.width/2, y: rect.size.height/2)
        let path = UIBezierPath(arcCenter: center, radius: rect.size.width/2-5, startAngle: 0, endAngle: -CGFloat.pi*percent, clockwise: false)
        path.lineWidth = 1.0
        path.stroke()
    }
    
}
