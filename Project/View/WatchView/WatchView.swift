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

    @IBOutlet weak var watchFace: WatchFace!
    @IBInspectable var interactable: Bool {
        set {
            watchFace.interactable = newValue
        }
        get {
            return watchFace.interactable
        }
    }

}