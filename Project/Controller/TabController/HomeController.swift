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
    @IBOutlet weak var stepLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SBManager.share.didUpdateStep = {
            self.updateView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    func updateView() {
        watchView.watchFace.setTime(Date())
        if let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) {
            let step = device.steps?.sortedArray(using: [NSSortDescriptor.init(key: "date", ascending: false)])[0] as? Step ?? Step()
            self.stepLabel.text = "\(step.steps) \(NSLocalizedString("STEPS", comment: ""))"
        }
    }
    
}
