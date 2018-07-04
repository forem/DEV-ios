//
//  WebViewController.swift
//  DEV
//
//  Created by Damodar Shenoy on 04/07/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webNavigationBar: UIToolbar!
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var forwardBarButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let devToURL = URL(string: "https://dev.to") {
            let devToURLRequest = URLRequest(url: devToURL)
            webView.load(devToURLRequest)
        }
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.webView.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        self.webView.goForward()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
