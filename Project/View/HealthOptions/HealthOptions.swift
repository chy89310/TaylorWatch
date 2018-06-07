//
//  HealthOptions.swift
//  Taylor
//
//  Created by Kevin Sum on 4/2/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

class HealthOptions: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum DisplayOption {
        case day
        case goal
        case measurements
        case month
        case week
    }
    
    @IBOutlet weak var monthOrWeekView: UIStackView!
    @IBOutlet weak var totalTitle: UILabel!
    @IBOutlet weak var totalCals: UILabel!
    @IBOutlet weak var totalSteps: UILabel!
    @IBOutlet weak var totalWalkAndRun: UILabel!
    @IBOutlet weak var averageTitle: UILabel!
    @IBOutlet weak var averageCals: UILabel!
    @IBOutlet weak var averageSteps: UILabel!
    @IBOutlet weak var averageWalkAndRun: UILabel!
    @IBOutlet weak var monthOrWeekGoalButton: UIButton!
    @IBOutlet weak var monthOrWeekMeasureButton: UIButton!
    
    @IBOutlet weak var dayView: UIStackView!
    
    @IBOutlet weak var goalView: UIStackView!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var goalPicker: UIPickerView!
    @IBOutlet weak var goalCancelButton: UIButton!
    @IBOutlet weak var goalApplyButton: UIButton!
    
    @IBOutlet weak var measurementsView: UIStackView!
    @IBOutlet weak var measureLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var weightText: UITextField!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var heightText: UITextField!
    @IBOutlet weak var measureCancelButton: UIButton!
    @IBOutlet weak var measureApplyButton: UIButton!
    
    var lastOption = DisplayOption.month
    var currentOption = DisplayOption.month
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Load view
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        if (nib.instantiate(withOwner: self, options: nil).count > 0) {
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            view.frame = bounds
            view.autoresizingMask = [UIViewAutoresizing.flexibleWidth,
                                     UIViewAutoresizing.flexibleHeight]
            addSubview(view)
            setupMonth(OrWeek: false)
            setupGoal(isWrite: false)
            setupMeasurements(isWrite: false)
            
            display(currentOption)
        }
    }
    
    func setupMonth(OrWeek isWeek: Bool) {
        monthOrWeekGoalButton.setTitle(NSLocalizedString("Set Goals", comment: ""), for: .normal)
        monthOrWeekMeasureButton.setTitle(NSLocalizedString("Body Measurements", comment: ""), for: .normal)
        totalTitle.text = NSLocalizedString(isWeek ? "Weekly Total" : "Monthly Total", comment: "")
        averageTitle.text = NSLocalizedString(isWeek ? "Weekly Average" : "Monthly Average", comment: "")
        totalWalkAndRun.isHidden = true
        averageWalkAndRun.isHidden = true
        let dataSet = Step.getSet(ofWeek: isWeek)
        let total = Int(dataSet.values.reduce(0, +))
        // Only count time stamp before now for average data
        let twelvehours: Double = 60*60*24
        let validCount = dataSet.keys.reduce(0) { (result, timestamp) -> Int in
            if timestamp-twelvehours < Date().timeIntervalSince1970 {
                return result+1
            } else {
                return result
            }
        }
        let average = validCount > 0 ? total/validCount : 0
        totalSteps.text = "\(total) \(NSLocalizedString("steps", comment: ""))"
        totalCals.text = "\(Int(CBUtils.caloriesFrom(step: total))) \(NSLocalizedString("cals", comment: ""))"
        averageSteps.text = "\(average) \(NSLocalizedString("steps", comment: ""))"
        averageCals.text = "\(Int(CBUtils.caloriesFrom(step: average))) \(NSLocalizedString("cals", comment: ""))"
    }
    
    func setupGoal(isWrite: Bool) {
        goalLabel.text = NSLocalizedString("Set Goals", comment: "")
        goalCancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        goalApplyButton.setTitle(NSLocalizedString("Apply", comment: ""), for: .normal)
        if isWrite {
            let steps = HealthOptions.goalForRow(goalPicker.selectedRow(inComponent: 0))
            UserDefaults.set(steps, forKey: .goal)
            SBManager.share.setTargetSteps(steps: steps)
        } else {
            goalPicker.selectRow(HealthOptions.rowForGoal(UserDefaults.int(of: .goal)), inComponent: 0, animated: false)
        }
    }
    
    func setupMeasurements(isWrite: Bool) {
        measureLabel.text = NSLocalizedString("Body Measurements", comment: "")
        genderLabel.text = NSLocalizedString("Gender", comment: "")
        weightLabel.text = "\(NSLocalizedString("Weight", comment: ""))(kg)"
        heightLabel.text = "\(NSLocalizedString("Height", comment: ""))(cm)"
        measureCancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        measureApplyButton.setTitle(NSLocalizedString("Apply", comment: ""), for: .normal)
        if isWrite {
            if let weightStr = weightText.text {
                UserDefaults.set(Int(weightStr), forKey: .weight)
            }
            if let heightStr = heightText.text {
                UserDefaults.set(Int(heightStr), forKey: .height)
            }
            let isMale =  genderButton.title(for: .normal) == NSLocalizedString("Male", comment: "")
            UserDefaults.set(isMale, forKey: .isMale)
        } else {
            let gender = NSLocalizedString(UserDefaults.bool(of: .isMale) ? "Male" : "Female", comment: "")
            genderButton.setTitle(gender, for: .normal)
            weightText.text = String(UserDefaults.int(of: .weight))
            heightText.text = String(UserDefaults.int(of: .height))
        }
    }
    
    func display(_ option: DisplayOption) {
        lastOption = currentOption
        currentOption = option
        self.dayView.isHidden = !(option == .day)
        self.monthOrWeekView.isHidden = !(option == .month)
        self.measurementsView.isHidden = !(option == .measurements)
        self.goalView.isHidden = !(option == .goal)
    }
    
    // MARK: - IBActions
    
    @IBAction func didGenderClick(_ sender: Any) {
        if genderButton.title(for: .normal) == NSLocalizedString("Male", comment: "") {
            genderButton.setTitle(NSLocalizedString("Female", comment: ""), for: .normal)
        } else {
            genderButton.setTitle(NSLocalizedString("Male", comment: ""), for: .normal)
        }
    }
    

    @IBAction func didSetGoalClick(_ sender: UIButton) {
        display(.goal)
    }
    
    @IBAction func didMeasurementClick(_ sender: UIButton) {
        display(.measurements)
    }
    
    @IBAction func didCancelClick(_ sender: UIButton) {
        didApplyOrCancelClick(isApply: false)
    }
    
    @IBAction func didApplyClick(_ sender: UIButton) {
        let appDele = UIApplication.shared.delegate as! AppDelegate
        if appDele.reach?.isReachable() ?? false {
            // Try to update user info with api
            var parameters = [String: Any]()
            switch currentOption {
            case .measurements:
                parameters["gender"] = genderButton.title(for: .normal) == NSLocalizedString("Male", comment: "") ? 1 : 0
                if let height = heightText.text {
                    parameters["height"] = height
                }
                if let weight = weightText.text {
                    parameters["weight"] = weight
                }
            case .goal:
                let steps = HealthOptions.goalForRow(goalPicker.selectedRow(inComponent: 0))
                parameters["target"] = steps
            default:
                break
            }
            if parameters.count > 0 {
                let hud = MBProgressHUD.showAdded(to: self, animated: true)
                DispatchQueue.global().async {
                    ApiHelper.shared.request(
                        name: .post_user,
                        method: .post,
                        parameters: parameters,
                        headers: AuthUtil.shared.header,
                        success: { (json, response) in
                            log.debug(json)
                            if json.dictionary?["status"]?.int == 200 {
                                DispatchQueue.main.async { hud.hide(animated: true) }
                            } else {
                                hud.mode = .text
                                if let errors = json.dictionary?["result"]?.dictionary?["error"]?.array {
                                    hud.label.text = errors[0].string
                                } else if let error = json.dictionary?["message"]?.string {
                                    hud.label.text = error
                                } else {
                                    hud.label.text = NSLocalizedString("Unknow Error", comment: "")
                                }
                                DispatchQueue.main.async { hud.hide(animated: true, afterDelay: 3.0) }
                            }
                    },
                        failure: { (error, response) in
                            hud.mode = MBProgressHUDMode.text
                            hud.label.text = error.localizedDescription
                            log.error(error.localizedDescription)
                            DispatchQueue.main.async { hud.hide(animated: true, afterDelay: 3.0) }
                    })
                }
            }
        }
        didApplyOrCancelClick(isApply: true)
    }
    
    func didApplyOrCancelClick(isApply: Bool) {
        switch currentOption {
        case .measurements:
            setupMeasurements(isWrite: isApply)
        case .goal:
            setupGoal(isWrite: isApply)
        default:
            break
        }
        display(lastOption)
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
    
    // Shared function to for RegisterController reuse
    
    class func numberOfGoals() -> Int {
        return 80
    }
    
    class func goalForRow(_ row: Int) -> Int {
        return 1000 + 1000 * row
    }
    
    class func rowForGoal(_ goal: Int) -> Int {
        if goal >= 1000 && goal <= 80000 {
            return (goal - 1000)/1000
        }
        return 0
    }
}
