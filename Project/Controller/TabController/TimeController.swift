//
//  TimeController.swift
//  Taylor
//
//  Created by Kevin Sum on 2/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit


class TimeController: BaseViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var _pickerView: UIPickerView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let date = Date()
        let calendar = Calendar.init(identifier: .iso8601)
        let component = calendar.dateComponents(in: .current, from: date)
        _pickerView.selectRow(component.hour ?? 0, inComponent: 0, animated: true)
        _pickerView.selectRow(component.minute ?? 0, inComponent: 2, animated: true)
        _pickerView.selectRow(component.second ?? 0, inComponent: 4, animated: true)
    }

    @IBAction func didSyncClick(_ sender: Any) {
        let date = Date()
        let calendar = Calendar.init(identifier: .iso8601)
        let component = calendar.dateComponents(in: .current, from: date)
        
        SBManager.share.setTime(
            year: component.year ?? 2018,
            month: component.month ?? 1,
            day: component.day ?? 1,
            hour: component.hour ?? 0,
            minute: component.minute ?? 0,
            second: component.second ?? 0,
            weekday: component.weekday ?? 0)
    }
    
    // MARK: - Picker view datasource & delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 24
        case 1:
            return 1
        case 2:
            return 60
        case 3:
            return 1
        case 4:
            return 60
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (component == 1 || component == 3 || component == 5) {
            return ":"
        } else {
            if (row < 10) {
                return "0\(row)"
            } else {
                return String(row)
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let date = Date()
        let calendar = Calendar.init(identifier: .iso8601)
        let component = calendar.dateComponents(in: .current, from: date)
        SBManager.share.setTime(
            year: component.year ?? 2018,
            month: component.month ?? 1,
            day: component.day ?? 1,
            hour: pickerView.selectedRow(inComponent: 0),
            minute: pickerView.selectedRow(inComponent: 2),
            second: pickerView.selectedRow(inComponent: 4),
            weekday: component.weekday ?? 0)
    }
}
