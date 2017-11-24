//
//  StepsController.swift
//  Taylor
//
//  Created by Kevin Sum on 1/12/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import MagicalRecord
import UIKit

class StepsController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var _tableView: UITableView!
    let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) ?? Device()
    var steps = [Step]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        steps = device.steps?.sortedArray(using: [NSSortDescriptor.init(key: "date", ascending: false)]) as! [Step]
        _tableView.reloadData()
        SBManager.share.didUpdateStep = {
            let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) ?? Device()
            self.steps = device.steps?.sortedArray(using: [NSSortDescriptor.init(key: "date", ascending: false)]) as! [Step]
            self._tableView.reloadData()
        }
    }

    // MARK: - Table view datasource and delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let step = steps[indexPath.row]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        cell.textLabel?.text = formatter.string(from: (step.date ?? NSDate()) as Date)
        cell.detailTextLabel?.text = String(step.steps)
        return cell
    }

}
