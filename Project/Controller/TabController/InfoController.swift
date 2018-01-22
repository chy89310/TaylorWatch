//
//  InfoController.swift
//  Taylor
//
//  Created by Kevin Sum on 28/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import HexColors
import MagicalRecord
import UIKit

class InfoController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    let device = SBManager.share.selectedDevice(in: NSManagedObjectContext.mr_default()) ?? Device.mr_createEntity()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Table view datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            if indexPath.row%2 == 1 {
                cell.backgroundColor = UIColor("#9b9b9b")
            } else {
                cell.backgroundColor = UIColor("#4a4a4a")
            }
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = NSLocalizedString("Watch Bettery", comment: "")
                cell.detailTextLabel?.text = "\(device?.battery ?? 100)%"
            case 1:
                cell.textLabel?.text = NSLocalizedString("Bluetooth", comment: "")
                cell.detailTextLabel?.text = "\(device?.system ?? "N/A")"
            case 2:
                cell.textLabel?.text = NSLocalizedString("Model Name", comment: "")
                cell.detailTextLabel?.text = "\(device?.serial ?? "N/A")"
            case 3:
                cell.textLabel?.text = NSLocalizedString("Pairing Code", comment: "")
                cell.detailTextLabel?.text = "\(device?.passcode ?? 000000)"
            case 4:
                cell.textLabel?.text = NSLocalizedString("Frame Number", comment: "")
                cell.detailTextLabel?.text = "\(device?.firmware ?? "N/A")"
            case 5:
                cell.textLabel?.text = NSLocalizedString("App Version", comment: "")
                #if DEBUG
                    cell.detailTextLabel?.text = "\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] ?? "1.0")(\(Bundle.main.infoDictionary!["CFBundleVersion"] ?? "1"))"
                #else
                    cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    
                #endif
            default:
                break
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "updateCell", for: indexPath)
            switch indexPath.row {
            case 6:
                cell.textLabel?.text = NSLocalizedString("Update APP", comment: "")
                cell.textLabel?.textColor = .black
            default:
                break
            }
            return cell
        }
    }

}
