//
//  DeviceInfoViewController.swift
//  Taylor
//
//  Created by Kevin on 23/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceInfoViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var _textView: UITextView!
    @IBOutlet weak var _tableview: UITableView!
    
    var peripheral: CBPeripheral?
    var advertisement: [String : Any]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if advertisement != nil {
            _textView.text = String.init(describing: advertisement)
        }
        if let device = peripheral {
            TaylorCentralManager.sharedInstance.centralManager.connect(device, options: nil)
        }
        TaylorCentralManager.sharedInstance.didFindCharacter = { (character) in
            self._tableview.reloadData()
        }
    }

    // MARK; - Table view datasource and delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TaylorCentralManager.sharedInstance.characters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "character", for: indexPath)
        let character = TaylorCentralManager.sharedInstance.characters[indexPath.row]
        cell.textLabel?.text = character.uuid._IQDescription()
        cell.detailTextLabel?.text = String.init(describing: character.properties)
        return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
