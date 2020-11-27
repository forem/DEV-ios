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

    var useDarkMode = false

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

    @objc func updateWebView() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let serverURL = appDelegate?.serverURL

        // Wait a split second if first launch (Hack, probably a race condition)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            self.webView.load(serverURL ?? "https://dev.to")
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
        return url.absoluteString.hasPrefix(AuthUrl.github) || url.absoluteString.hasPrefix(AuthUrl.twitter)
    }

    // MARK: - Theme configs

    private func ensureShellState() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        switch webView.userData?.theme() {
        case .night:
            useDarkMode = true
            navigationToolBar.barTintColor = ThemeColors.darkBackgroundColor
            view.backgroundColor = ThemeColors.darkBackgroundColor
        case .hacker:
            useDarkMode = true
            navigationToolBar.barTintColor = UIColor.black
            view.backgroundColor = UIColor.black
        default:
            useDarkMode = false
            navigationToolBar.barTintColor = UIColor.white
            view.backgroundColor = UIColor.white
        }

        navigationToolBar.isTranslucent = !useDarkMode
        safariButton.tintColor = useDarkMode ? UIColor.white : ThemeColors.darkBackgroundColor
        backButton.tintColor = useDarkMode ? UIColor.white : ThemeColors.darkBackgroundColor
        forwardButton.tintColor = useDarkMode ? UIColor.white : ThemeColors.darkBackgroundColor
        refreshButton.tintColor = useDarkMode ? UIColor.white : ThemeColors.darkBackgroundColor
        activityIndicator.color = useDarkMode ? UIColor.white : ThemeColors.darkBackgroundColor
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Notifications Functions
    func askForNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { [weak self] granted, _  in
            guard let self = self, granted else { return }
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
        if segue.identifier == DoAction.openExternalURL,
            let externalPage = segue.destination as? BrowserViewController {

            externalPage.destinationUrl = sender as? URL
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if !useDarkMode && traitCollection.userInterfaceStyle == .dark {
            return UIStatusBarStyle.init(rawValue: ThemeColors.statusBarStyleDarkContentRawValue)!
        }
        return useDarkMode ? .lightContent : .default
    }

    private func setupObservers() {
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
