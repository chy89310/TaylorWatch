//
//  HomeController.swift
//  Taylor
//
//  Created by Kevin Sum on 19/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import MagicalRecord
import UIKit

class HomeController: BaseViewController {

    @IBOutlet weak var watchView: WatchView!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        watchView.updateAsset(withDial: false)
        SBManager.share.didUpdateStep = {
            self.updateView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    func updateView() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        formatter.dateFormat = "MMM dd"
        dateLabel.text = formatter.string(from: date)
        formatter.dateFormat = "EE"
        weekDayLabel.text = formatter.string(from: date)
        watchView.watchFace.setTime(Date())
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            let step = device.steps?.sortedArray(using: [NSSortDescriptor.init(key: "date", ascending: false)])[0] as? Step ?? Step()
            self.stepLabel.text = "\(step.steps) \(NSLocalizedString("STEPS", comment: ""))"
            let cals = Int(CBUtils.caloriesFrom(step: Int(step.steps)))
            self.caloriesLabel.text = "\(cals) \(NSLocalizedString("CALS", comment: ""))"
        }
    }
    
}
