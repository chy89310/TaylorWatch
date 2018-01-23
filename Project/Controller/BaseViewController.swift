//
//  BaseViewController.swift
//  Project
//
//  Created by Kevin Sum on 10/7/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        log.verbose("\(self) init with coder \(aDecoder)")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        log.verbose("\(self) init with nib \(nibNameOrNil ?? "nil") and bundle \(String(describing: nibBundleOrNil))")
    }
    
    deinit {
        log.verbose("\(self)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: false)
    }

}
