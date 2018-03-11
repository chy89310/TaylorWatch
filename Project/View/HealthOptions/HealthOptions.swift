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
    
    @IBOutlet weak var dayView: UIStackView!
    
    @IBOutlet weak var goalView: UIStackView!
    @IBOutlet weak var goalPicker: UIPickerView!
    
    @IBOutlet weak var measurementsView: UIStackView!
    @IBOutlet weak var genderText: UITextField!
    @IBOutlet weak var weightText: UITextField!
    @IBOutlet weak var heightText: UITextField!
    
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
        if isWrite {
            let steps = goalForRow(goalPicker.selectedRow(inComponent: 0))
            UserDefaults.set(steps, forKey: .goal)
            SBManager.share.setTargetSteps(steps: steps)
        } else {
            goalPicker.selectRow(rowForGoal(UserDefaults.int(of: .goal)), inComponent: 0, animated: false)
        }
    }
    
    func setupMeasurements(isWrite: Bool) {
        if isWrite {
            if let weightStr = weightText.text {
                UserDefaults.set(Int(weightStr), forKey: .weight)
            }
            if let heightStr = heightText.text {
                UserDefaults.set(Int(heightStr), forKey: .height)
            }
        } else {
            genderText.text = UserDefaults.bool(of: .isMale) ? "Male" : "Female"
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
        return 80
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = String(goalForRow(row))
        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName:UIColor.white])
    }
    
    func goalForRow(_ row: Int) -> Int {
        return 1000 + 1000 * row
    }
    
    func rowForGoal(_ goal: Int) -> Int {
        if goal >= 1000 && goal <= 80000 {
            return (goal - 1000)/1000
        }
        return 0
    }
}
