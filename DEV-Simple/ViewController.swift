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
import NotificationBanner

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
    static let didCompleteTask = Notification.Name("didCompleteTask")
    static let completedLengthyDownload = Notification.Name("completedLengthyDownload")
}

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var safariButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var lightAlpha = CGFloat(0.2)

    let pushNotifications = PushNotifications.shared
    lazy var errorBanner: NotificationBanner = {
        return NotificationBanner(title: "Network not reachable", style: .danger)
    }()

    struct UserData: Codable {
        var id: Int
    }

    var devToURL =  "https://dev.to"

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        backButton.isEnabled = false
        forwardButton.isEnabled = false
        webView.navigationDelegate = self
        webView.customUserAgent = "DEV-Native-ios"
        webView.scrollView.scrollIndicatorInsets.top = view.safeAreaInsets.top + 50
        webView.load(devToURL)
        webView.configuration.userContentController.add(self, name: "haptic")
        webView.allowsBackForwardNavigationGestures = true
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new, .old], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: [.new, .old], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new, .old], context: nil)
        addShellShadow()
        let notificationName = Notification.Name("updateWebView")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateWebView),
            name: notificationName,
            object: nil)

        }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged),
            name: .flagsChanged,
            object: Network.reachability)
    }

    // MARK: - Reachability
    @objc private func reachabilityChanged(note: Notification) {
        guard let reachability = note.object as? Reachability else {
            return
        }

        switch reachability.status {
        case .wifi:
            if errorBanner.isDisplaying {
                errorBanner.dismiss()
                displayWifiBanner()
            }
        case .wwan:
            if errorBanner.isDisplaying {
                errorBanner.dismiss()
                displayCellularBanner()
            }
        case .unreachable:
            errorBanner.show()
        }
    }

    private func displayWifiBanner() {
        let banner = NotificationBanner(title: "Re-connected to WiFi", style: .success)
        banner.duration = 1.5
        banner.show()
    }

    private func displayCellularBanner() {
        let banner = NotificationBanner(title: "Re-connected to Cellular", style: .warning)
        banner.duration = 1.5
        banner.show()
    }

    // MARK: - IBActions
    @IBAction func backButtonTapped(_ sender: Any) {
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

    // MARK: - Observers
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        if let url = webView.url {
             webView.scrollView.isScrollEnabled = !(url.path.hasPrefix("/connect")) //Remove scroll if /connect view
        }
        modifyShellDesign()
    }

    @objc func updateWebView() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let serverURL = appDelegate?.serverURL
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let `self` = self else {
                return
            }
            // Wait a split second if first launch (Hack, probably a race condition)
            self.webView.load(serverURL ?? "https://dev.to")
        }
    }

    // MARK: - WKWebView Delegate Functions

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let js = "document.getElementsByTagName('body')[0].getAttribute('data-user-status')"
        webView.evaluateJavaScript(js) { [weak self] result, error in

            guard let `self` = self else {
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

        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, decidePolicyFor
        navigationAction: WKNavigationAction,decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let policy = navigationPolicy(url: url, navigationType: navigationAction.navigationType)
        decisionHandler(policy)
    }

    // MARK: - Action Policy
    func navigationPolicy(url: URL, navigationType: WKNavigationType) -> WKNavigationActionPolicy {

        if url.scheme == "mailto" {
            openURL(url)
            return .cancel
        } else if url.absoluteString == "about:blank" {
            return .allow
        } else if isAuthLink(url) {
            return .allow
        } else if url.host != "dev.to" && navigationType.rawValue == 0 {
            performSegue(withIdentifier: DoAction.openExternalURL, sender: url)
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

    // MARK: - External Safari call
    func openInBrowser() {
        if let url = webView.url {
            UIApplication.shared.open(url, options: [:])
        }
    }

    // MARK: - Auth
    func isAuthLink(_ url: URL) -> Bool {
        if url.absoluteString.hasPrefix("https://github.com/login") {
            return true
        }
        if url.absoluteString.hasPrefix("https://api.twitter.com/oauth") {
            return true
        }
        return false
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
                } catch {
                    print("Error info: \(error)")
                }
            }
        }
    }

    func modifyShellDesign() {
        let js = "document.getElementById('page-content').getAttribute('data-current-page')"
        webView.evaluateJavaScript(js) { [weak self] result, error in

            guard let `self` = self else {
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

    // MARK: - Theme configs
    func addShellShadow() {
        webView.layer.shadowColor = UIColor.gray.cgColor
        webView.layer.shadowOffset = CGSize(width: 0.0, height: 0.9)
        webView.layer.shadowOpacity = 0.5
        webView.layer.shadowRadius = 0.0
    }

    func removeShellShadow() {
        webView.layer.shadowOpacity = 0.0
    }

    // MARK: - Notifications Functions
    func askForNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { [weak self] granted, _  in

            guard let `self` = self else {
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

    // MARK: - Navegation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DoAction.openExternalURL {
            if let externalPage = segue.destination as? BrowserViewController {
                externalPage.destinationUrl = sender as? URL
            }
        }
    }
}

extension ViewController: WKScriptMessageHandler {

    // MARK: - webkit messagehandler protocol
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "haptic", let hapticType = message.body as? String {
            switch hapticType {
            case "heavy":
                let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                heavyImpact.impactOccurred()
            case "light":
                let lightImpact = UIImpactFeedbackGenerator(style: .light)
                lightImpact.impactOccurred()
            case "medium":
                let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
                mediumImpact.impactOccurred()
            default:
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }
}

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}
