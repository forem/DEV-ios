//
//  LoginViewContoller.swift
//  DEV
//
//  Created by Ceri-anne Jackson on 27/08/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation
import WebKit

class LoginViewController: DevWebViewController {
    
    override func viewDidLoad() {
        self.webURL = DevServiceURL.login.fullURL
        super.viewDidLoad()
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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let tabBar = storyboard.instantiateViewController(withIdentifier: "TabBar") as? UITabBarController else {
            return
        }
        
        guard let appDelegate  = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
       
        appDelegate.window?.rootViewController = tabBar
        
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
