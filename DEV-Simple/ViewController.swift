//
//  ViewController.swift
//  DEV-Simple
//
//  Created by Ben Halpern on 11/1/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import AVKit
import ForemWebView
import PushNotifications
import NotificationBanner

class ViewController: UIViewController {

    private var observations: [NSKeyValueObservation] = []

    @IBOutlet weak var webView: ForemWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var safariButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var navigationToolBar: UIToolbar!

    var pushNotificationSubscription = ""

    lazy var errorBanner: NotificationBanner = {
        let banner = NotificationBanner(title: "Network not reachable", style: .danger)
        banner.autoDismiss = false
        banner.dismissOnTap = true
        return banner
    }()

    var devToURL: String = {
        if let developmentURL = ProcessInfo.processInfo.environment["DEV_URL"] {
            return developmentURL
        }
        return "https://dev.to"
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        webView.foremWebViewDelegate = self
        webView.load(devToURL)

        setupObservers()
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
        guard let reachability = note.object as? Reachability else { return }
        switch reachability.status {
        case .wifi, .wwan:
            if errorBanner.isDisplaying {
                errorBanner.dismiss()
            }
        default: ()
        }
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

    @IBAction func refreshButtonTapped(_ sender: Any) {
        webView.reload()
    }

    @IBAction func safariButtonTapped(_ sender: Any) {
        openInBrowser()
    }

    @objc func updateWebView(_ notification: NSNotification) {
        guard let url = notification.userInfo?["url"] as? String else { return }
        webView.load(url)
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
        return url.absoluteString.hasPrefix(AuthUrl.github) || url.absoluteString.hasPrefix(AuthUrl.twitter)
    }

    // MARK: - Theme configs

    private func ensureShellState() {
        ensurePushNotificationsRegistration()

        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward

        ThemeManager.applyTheme(to: self)
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Notifications Functions

    func ensurePushNotificationsRegistration() {
        if let userID = webView.userData?.userID, pushNotificationSubscription.isEmpty {
            pushNotificationSubscription = "user-notifications-\(userID)"
            do {
                try PushNotifications.shared.addDeviceInterest(interest: pushNotificationSubscription)
            } catch {
                // Clear out the subscription because it failed so it can try again next time
                pushNotificationSubscription = ""
            }
        } else if webView.userData?.userID == nil && !pushNotificationSubscription.isEmpty {
            // This means we had already subscribed to an interest for the logged-in user but
            // since `webView.userData` is now nil the user has just logged out.
            do {
                try PushNotifications.shared.removeDeviceInterest(interest: pushNotificationSubscription)
                pushNotificationSubscription = ""
            } catch {
                print("Failed to remove the interest")
            }
        }
    }

    // MARK: - Navegation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DoAction.openExternalURL,
            let externalPage = segue.destination as? BrowserViewController {

            externalPage.destinationUrl = sender as? URL
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if !ThemeManager.useLightIcons && traitCollection.userInterfaceStyle == .dark {
            return UIStatusBarStyle.init(rawValue: ThemeColors.statusBarStyleDarkContentRawValue)!
        }
        return ThemeManager.useLightIcons ? .lightContent : .default
    }

    private func setupObservers() {
        let notificationName = Notification.Name.updateWebView
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateWebView(_:)),
                                               name: notificationName,
                                               object: nil)

        observations = [
            webView.observe(\ForemWebView.userData) { [weak self] (_, _) in self?.ensureShellState() },
            webView.observe(\ForemWebView.canGoBack) { [weak self] (_, _) in self?.ensureShellState() },
            webView.observe(\ForemWebView.canGoForward) { [weak self] (_, _) in self?.ensureShellState() },
            webView.observe(\ForemWebView.url) { [weak self] (_, _) in self?.ensureShellState() }
        ]
    }
}

extension ViewController: ForemWebViewDelegate {
    func willStartNativeVideo(playerController: AVPlayerViewController) {
        if playerController.presentingViewController == nil {
            present(playerController, animated: true) {
                playerController.player?.play()
            }
        }
    }

    func requestedExternalSite(url: URL) {
        performSegue(withIdentifier: DoAction.openExternalURL, sender: url)
    }

    func requestedMailto(url: URL) {
        openURL(url)
    }

    func didStartNavigation() {
        let reachability = Network.reachability
        guard let isNetworkReachable = reachability?.isReachable, isNetworkReachable else {
            errorBanner.show()
            return
        }
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func didFinishNavigation() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
}
