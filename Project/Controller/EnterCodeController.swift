//
//  EnterCodeController.swift
//  Taylor
//
//  Created by Kevin Sum on 24/11/2017.
//  Copyright © 2017 KevinSum. All rights reserved.
//

import UIKit
import CoreBluetooth

class EnterCodeController: BaseViewController {

    @IBOutlet weak var hourHand: UITextField!
    @IBOutlet weak var minusHand: UITextField!
    var peripheral: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func didDoneClick(_ sender: Any) {
//        let hourInt = UInt8(hourHand.text ?? "0") ?? 0xff
//        let minusInt = UInt8(minusHand.text ?? "0") ?? 0xff
        var hourInt = 0
        var p = Array(hourHand.text ?? "0").count-1
        for c in Array(hourHand.text ?? "0") {
            if let intValue = Int(String(c)) {
                hourInt += Int(powf(16,Float(p)))*intValue
                p -= 1
            }
        }
        var minusInt = 0
        p = Array(minusHand.text ?? "0").count-1
        for c in Array(minusHand.text ?? "0") {
            if let intValue = Int(String(c)) {
                minusInt += Int(powf(16,Float(p)))*intValue
                p -= 1
            }
        }
        let value = Data.init(bytes: [0x00,UInt8(minusInt),UInt8(hourInt)])
        TaylorCentralManager.sharedInstance.peripheral(peripheral, write: value)
        self.mz_dismissFormSheetController(animated: true, completionHandler: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
