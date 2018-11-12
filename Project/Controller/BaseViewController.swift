//
//  BaseViewController.swift
//  Project
//
//  Created by Connectz technology co., ltd on 10/7/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let textAttributes = [NSForegroundColorAttributeName: UIColor("#FDDFC0") ?? .white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    func showAlert(title: String, message: String, showDismiss: Bool = false, ok_handler handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: handler))
        if showDismiss {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }

}
