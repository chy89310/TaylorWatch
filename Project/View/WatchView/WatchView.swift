//
//  WatchView.swift
//  Taylor
//
//  Created by Kevin Sum on 16/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit
import Foundation

class WatchView: DesignableView {

    @IBOutlet weak var beltImage: UIImageView!
    @IBOutlet weak var watchFace: WatchFace!
    @IBInspectable var interactable: Bool {
        set {
            watchFace.interactable = newValue
        }
        get {
            return watchFace.interactable
        }
    }
    
    override func setup() {
        super.setup()
        var belt = "601_taylor_belt"
        switch Helper.targetName {
        case "TAYLOR":
            belt = "601_taylor_belt"
        case "FOXTER":
            belt = "601_foxter_belt"
        case "SEAGULL":
            belt = "301_belt"
        default:
            break;
        }
        if let beltImg = UIImage(named: belt) {
            beltImage.image = beltImg
        }
    }
    
    func updateAsset(withDial: Bool) {
        beltImage.image = SBManager.share.getAsset(.belt)
        watchFace.updateAsset(withDial: withDial)
    }

}
