//
//  ViewController.swift
//  Project
//
//  Created by Kevin Sum on 8/6/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var watchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func switchMode(sender: UIButton) {
        if (sender == phoneButton) {
            phoneButton.backgroundColor = .blue
            phoneButton.tintColor = .white
            watchButton.backgroundColor = .white
            watchButton.tintColor = .blue
            TaylorCentralManager.sharedInstance.connectAction()
//            TaylorPeripheralManager.sharedInstance.reset()
        } else if (sender == watchButton) {
            phoneButton.backgroundColor = .white
            phoneButton.tintColor = .blue
            watchButton.backgroundColor = .blue
            watchButton.tintColor = .white
            TaylorPeripheralManager.sharedInstance.advertiseAction()
            TaylorPeripheralManager.sharedInstance.didSubscribe = { (subscribe, central) in
                if (subscribe) {
                    self.watchButton.setTitle("Subscribed", for: .normal)
                } else {
                    self.watchButton.setTitle("Unsubscribed", for: .normal)
                }
            }
//            TaylorCentralManager.sharedInstance.reset()
        }
    }

    @IBAction func didPhoneClick(_ sender: Any) {
        switchMode(sender: sender as! UIButton)
    }
    
    @IBAction func didWatchClick(_ sender: Any) {
        switchMode(sender: sender as! UIButton)
    }

}

