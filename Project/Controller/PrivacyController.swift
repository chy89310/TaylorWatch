//
//  PrivacyController.swift
//  Taylor
//
//  Created by Kevin Sum on 6/11/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit
import SwiftyJSON
import WebKit

class PrivacyController: BaseViewController {
    
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var agreeButton: UIBarButtonItem!
    
    let observerKeyPath = "estimatedProgress"
    var json: JSON?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        agreeButton.title = NSLocalizedString("I accept", comment: "")
        cancelButton.title = NSLocalizedString("I refuse", comment: "")
        
        if let name = json?.dictionary?["result"]?.dictionary?["title"]?.string {
            title = name
        }

        if let html = json?.dictionary?["result"]?.dictionary?["content"]?.string {
            // use js injection to change the font size and font color
            let jsScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta); document.getElementsByTagName('html')[0].style.color='white';"
            let userScript = WKUserScript(source: jsScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            let userContentCtrl = WKUserContentController()
            userContentCtrl.addUserScript(userScript)
            let webConfig = WKWebViewConfiguration()
            webConfig.userContentController = userContentCtrl
            let webView = WKWebView(frame: webViewContainer.bounds, configuration: webConfig)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webViewContainer.addSubview(webView)
            
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    @IBAction func didCancelClick(_ sender: Any) {
        if let navigate = self.navigationController {
            navigate.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didAgreeClick(_ sender: Any) {
        if let version = json?.dictionary?["result"]?.dictionary?["version"]?.int {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            DispatchQueue.global().async {
                ApiHelper.shared.request(
                    name: .post_user,
                    method: .post,
                    parameters: ["privacy_version": version],
                    headers: AuthUtil.shared.header,
                    success: { (json, response) in
                        DispatchQueue.main.async { hud.hide(animated: true) }
                        self.performSegue(withIdentifier: "showWatch", sender: nil)
                },
                    failure: { (error, response) in
                        hud.mode = .text
                        hud.label.text = error.localizedDescription
                        log.error(error.localizedDescription)
                        DispatchQueue.main.async { hud.hide(animated: true, afterDelay: 3.0) }
                })
            }
        } else {
            performSegue(withIdentifier: "showWatch", sender: nil)
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
