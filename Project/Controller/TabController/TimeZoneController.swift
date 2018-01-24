//
//  TimeZoneController.swift
//  Taylor
//
//  Created by Kevin Sum on 25/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import IQKeyboardManagerSwift
import UIKit

class TimeZoneController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var _tableView: UITableView!
    @IBOutlet weak var mapView: UIImageView!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var toolBar: UIToolbar!
    
    var timeZones = NSTimeZone.knownTimeZoneNames
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didToggle(_ sender: UIButton) {
        if self.mapView.isHidden {
            sender.titleLabel?.text = "Choose a time zone fa:angleup"
        } else {
            sender.titleLabel?.text = "Choose a time zone fa:angledown"
        }
        sender.parseIcon()
        UIView.animate(withDuration: 0.2) {
            self.mapView.isHidden = !self.mapView.isHidden
            self.mapView.alpha = self.mapView.isHidden ? 0.0 : 1.0
        }
    }
    
    @IBAction func didDoneClick(_ sender: Any) {
        searchBar.resignFirstResponder()
    }

    @IBAction func didCancelClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UITableView datasource and delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeZones.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeZoneCell", for: indexPath)
        cell.textLabel?.text = timeZones[indexPath.row]
        return cell
    }
    
    // MARK: - UISearchBar delegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.inputAccessoryView = toolBar
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            timeZones = NSTimeZone.knownTimeZoneNames.filter {
                $0.contains(searchText)
            }
        } else {
            timeZones = NSTimeZone.knownTimeZoneNames
        }
        _tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if !mapView.isHidden {
            didToggle(toggleButton)
        }
    }
}
