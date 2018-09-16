//
//  LoginViewContoller.swift
//  DEV
//
//  Created by Ceri-anne Jackson on 27/08/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    weak var loginCoordinator: LoginCoordinator?
    
    var webURL: URL?
    
    override func viewDidLoad() {
        self.webURL = DevServiceURL.login.fullURL
        super.viewDidLoad()
        setupWebView()
    }
    
    private func setupWebView() {
        webView.navigationDelegate = self
        if let url = webURL {
            webView.load(URLRequest(url: url))
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        removeNavBar()
    }
    
    func removeNavBar() {
        let js = "document.getElementsByClassName('top-bar')[0].style.display = 'none'"
        webView.evaluateJavaScript(js)
    }

}

extension LoginViewController {
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
       
        if let urlString = webView.url?.absoluteString {
            redirect(to: urlString)
        }
        
    }
    
    func redirect(to urlString: String) {
        
        if !loggedIn(urlString: urlString) {
            return
        }
        
        self.dismiss(animated: true)
        loginCoordinator?.finish()
        
    }
    
    func loggedIn(urlString: String) -> Bool {
        
        if urlString.contains("returning-user=true") {
            return true
        }
        
        if urlString.contains("signed-in-already") {
            return true
        }
        
        return false
        
    }
    
}
