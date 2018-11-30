//
//  ViewController.swift
//  DEV-Simple
//
//  Created by Ben Halpern on 11/1/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications
import PushNotifications

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
    static let didCompleteTask = Notification.Name("didCompleteTask")
    static let completedLengthyDownload = Notification.Name("completedLengthyDownload")
}

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var safariButton: UIButton!
    
    var lightAlpha = CGFloat(0.2)
    
    let pushNotifications = PushNotifications.shared
    
    struct UserData: Codable {
        var id: Int
    }
    
    var devToURL = URL(string: "https://dev.to")
    
    override func viewDidLoad() {
        webView.customUserAgent = "DEV-Native-ios"
        webView.scrollView.scrollIndicatorInsets.top = view.safeAreaInsets.top + 50

        if let url = devToURL {
             webView.load(URLRequest(url: url))
        }
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new, .old], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: [.new, .old], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new, .old], context: nil)
        addShellShadow()
        let notificationName = Notification.Name("updateWebView")
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateWebView), name: notificationName, object: nil)
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        print("back")
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func forwardButtonTapped(_ sender: Any) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @IBAction func safariButtonTapped(_ sender: Any) {
        openInBrowser()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        backButton.isEnabled = webView.canGoBack
        backButton.alpha = webView.canGoBack ? 0.9 : lightAlpha
        forwardButton.isEnabled = webView.canGoForward
        forwardButton.alpha = webView.canGoForward ? 0.9 : lightAlpha
        if let url = webView.url {
             webView.scrollView.isScrollEnabled = !(url.path.hasPrefix("/connect")) //Remove scroll if /connect view
        }
        modifyShellDesign()
    }
    
    @objc func updateWebView() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let serverURL = appDelegate.serverURL
        let url = URL(string: serverURL ?? "https://dev.to")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let `self` = self else {
                //self doesn't exist
                return
            }
            
            // Wait a split second if first launch (Hack, probably a race condition)
            self.webView.load(URLRequest(url: url!))
        }
        
    }

    
    func askForNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge];
        center.requestAuthorization(options: options) { [weak self] (granted, error) in
            
            guard let `self` = self else {
                //self doesn't exist
                return
            }
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func openInBrowser() {
        if let url = webView.url {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        let js = "document.getElementsByTagName('body')[0].getAttribute('data-user-status')"
        webView.evaluateJavaScript(js) { [weak self] result, error in
            
            guard let `self` = self else {
                //self doesn't exist
                return
            }
            
            if let error = error {
                print("Error getting user data: \(error)")
            }
            
            if let jsonString = result as? String {
                self.modifyShellDesign()
                if jsonString == "logged-in" {
                    self.populateUserData()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
       
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let policy = navigationPolicy(url: url, navigationType: navigationAction.navigationType)
        decisionHandler(policy)
    }
    
    func navigationPolicy(url: URL, navigationType: WKNavigationType) -> WKNavigationActionPolicy {
        
        if url.scheme == "mailto" {
            openURL(url)
            return .cancel
        } else if url.absoluteString == "about:blank" {
            return .allow
        } else if isAuthLink(url) {
            return .allow
        } else if url.host != "dev.to" && navigationType.rawValue == 0 {
            loadInBrowserView(url: url)
            return .cancel
        } else {
            return .allow
        }
    }
    
    func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func isAuthLink(_ url: URL) -> Bool {
        if url.absoluteString.hasPrefix("https://github.com/login") {
            return true
        }
        if url.absoluteString.hasPrefix("https://api.twitter.com/oauth") {
            return true
        }
        return false
    }
    
    func loadInBrowserView(url: URL) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let controller = storyboard.instantiateViewController(withIdentifier: "Browser") as? BrowserViewController {
            controller.destinationUrl = url
            present(controller, animated: true, completion: nil)
        }
    }

    func populateUserData() {
        
        let js = "document.getElementsByTagName('body')[0].getAttribute('data-user')"
        webView.evaluateJavaScript(js) { result, error in
            
            if let error = error {
                print("Error getting user data: \(error)")
            }
            if let jsonString = result as? String {
                do {
                    let jsonDecoder = JSONDecoder()
                    let user = try jsonDecoder.decode(UserData.self, from: Data(jsonString.utf8))
                    let notificationSubscription = "user-notifications-\(String(user.id))"
                    try? self.pushNotifications.subscribe(interest: notificationSubscription)
                }
                catch {
                    print("Error info: \(error)")
                }
            }
        }
    }
    
    func modifyShellDesign() {
        let js = "document.getElementById('page-content').getAttribute('data-current-page')"
        webView.evaluateJavaScript(js) { [weak self] result, error in
            
            guard let `self` = self else {
                //self doesn't exist
                return
            }
            
            if let error = error {
                print("Error getting user data: \(error)")
            }
            do {
                if result as? String == "stories-show" {
                    self.removeShellShadow()
                } else {
                    self.addShellShadow()
                }
            }
        }
    }
    
    func addShellShadow() {
        webView.layer.shadowColor = UIColor.gray.cgColor
        webView.layer.shadowOffset = CGSize(width: 0.0, height: 0.9)
        webView.layer.shadowOpacity = 0.5
        webView.layer.shadowRadius = 0.0
    }
    
    func removeShellShadow() {
        webView.layer.shadowOpacity = 0.0
    }
}
