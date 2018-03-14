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
    @IBOutlet weak var stepView: StepPercentView!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update ANCS notification
        var enabledTypes: [SBManager.MESSAGE_TYPE] = []
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            for (type, _) in SBManager.share.messageMap {
                if device.notification?.isTypeOn(type) ?? false {
                    enabledTypes.append(type)
                }
            }
            SBManager.share.setMessageEnabled(with: (device.notification?.isOn ?? true) ? enabledTypes : [])
        }
        
        
        SBManager.share.didUpdateStep = {
            self.updateView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    func updateView() {
        watchView.updateAsset(withDial: false)
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMM dd"
        dateLabel.text = formatter.string(from: date)
        formatter.dateFormat = "EE"
        weekDayLabel.text = formatter.string(from: date)
        watchView.watchFace.setTime(Date())
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
