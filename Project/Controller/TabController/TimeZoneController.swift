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
    @IBOutlet weak var _mapView: UIImageView!
    @IBOutlet weak var _toggleButton: UIButton!
    @IBOutlet weak var _searchBar: UISearchBar!
    @IBOutlet weak var _toolBar: UIToolbar!
    
    let timeZoneMap:[String:String] = ["Asia/Calcutta"      : "5-3",
                                       "Asia/Colombo"       : "5-3",
                                       "Asia/Rangoon"       : "6-3",
                                       "Asia/Yangon"        : "6-3",
                                       "Indian/Cocos"       : "6-3",
                                       "Australia/Darwin"   : "9-3"]
    var timeZones = NSTimeZone.knownTimeZoneNames
    var selectedTimeZone = NSTimeZone.system
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf:[UISearchBar.self]).tintColor = .white
        
        if let timeZoneName = UserDefaults.string(of: .timezone),
            let timezone = TimeZone(identifier: timeZoneName) {
            selectedTimeZone = timezone
        }
        updateMapView()
    }
    
    func updateMapView() {
        let timeZoneOffset = selectedTimeZone.secondsFromGMT()/3600
        var mapImage = String(timeZoneOffset)
        if timeZoneOffset < -9 {
            mapImage = "-9"
        } else if timeZoneOffset == -2 {
            mapImage = "-3"
        } else if timeZoneOffset > 12 {
            mapImage = "12"
        }
        if timeZoneMap.keys.contains(selectedTimeZone.identifier) {
            mapImage = timeZoneMap[selectedTimeZone.identifier] ?? mapImage
        }
        _mapView.image = UIImage(named: mapImage)
    }
    
    func showMapView(_ show: Bool) {
        if show == _mapView.isHidden {
            didToggle(_toggleButton)
        }
    }
    
    @IBAction func didToggle(_ sender: UIButton) {
        if _mapView.isHidden {
            sender.titleLabel?.text = "Choose a time zone fa:angleup"
        } else {
            sender.titleLabel?.text = "Choose a time zone fa:angledown"
        }
        sender.parseIcon()
        UIView.animate(withDuration: 0.2) {
            self._mapView.isHidden = !self._mapView.isHidden
            self._mapView.alpha = self._mapView.isHidden ? 0.0 : 1.0
        }
    }
    
    @IBAction func didDoneClick(_ sender: Any) {
        _searchBar.resignFirstResponder()
    }

    @IBAction func didCancelClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didApplyClick(_ sender: Any) {
        NSTimeZone.default = selectedTimeZone
        UserDefaults.set(selectedTimeZone.identifier, forKey: .timezone)
        didCancelClick(sender)
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
        let bgView = UIView()
        bgView.backgroundColor = UIColor("#FDDFC0")
        cell.selectedBackgroundView = bgView
        let zone = NSTimeZone(name: timeZones[indexPath.row])
        cell.textLabel?.text = timeZones[indexPath.row]
        cell.detailTextLabel?.text = zone?.abbreviation
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let timezone = TimeZone(identifier: timeZones[indexPath.row]) {
            _searchBar.resignFirstResponder()
            selectedTimeZone = timezone
            updateMapView()
            showMapView(true)
        }
    }
    
    // MARK: - UISearchBar delegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.inputAccessoryView = _toolBar
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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showMapView(true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showMapView(false)
    }
}
