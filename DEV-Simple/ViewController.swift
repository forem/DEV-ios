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

class ViewController: UIViewController {

    private var observations: [NSKeyValueObservation] = []

    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var webView: DEVWebView!
    @IBOutlet weak var safariButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var navigationToolBar: UIToolbar!

    var useDarkMode = false

    let pushNotifications = PushNotifications.shared
    lazy var errorBanner: NotificationBanner = {
        let banner = NotificationBanner(title: "Network not reachable", style: .danger)
        banner.autoDismiss = false
        banner.dismissOnTap = true
        return banner
    }()

    var videoPlayerView: DEVAVPlayerView?
    lazy var mediaManager: MediaManager = {
        return MediaManager(webView: self.webView, devToURL: self.devToURL)
    }()

    var devToURL: String = {
        if let developmentURL = ProcessInfo.processInfo.environment["DEV_URL"] {
            return developmentURL
        }
        return "https://dev.to"
    }()
    lazy var devToHost: String? = {
        var url = URL(string: self.devToURL)
        return url?.host
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return videoPlayerView?.currentState == .fullscreen ? .allButUpsideDown : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        webView.setup(navigationDelegate: self, messageHandler: self)
        webView.scrollView.verticalScrollIndicatorInsets.top = view.safeAreaInsets.top + 50
        webView.load(devToURL)

        setupObservers()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else {
                return
            }
            // Wait a split second if first launch (Hack, probably a race condition)
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

    func populateUserData() {
        webView.fetchUserData { user in
            guard let user = user else { return }
            let notificationSubscription = "user-notifications-\(String(user.userID))"
            try? self.pushNotifications.addDeviceInterest(interest: notificationSubscription)
            if user.configBodyClass.contains("night-theme") {
                self.applyDarkTheme()
            }
        }
    }

    private func applyDarkTheme() {
        useDarkMode = true
        setNeedsStatusBarAppearanceUpdate()
        navigationToolBar.isTranslucent = false
        navigationToolBar.barTintColor = ThemeColors.darkBackgroundColor
        safariButton.tintColor = UIColor.white
        backButton.tintColor = UIColor.white
        forwardButton.tintColor = UIColor.white
        refreshButton.tintColor = UIColor.white
        view.backgroundColor = ThemeColors.darkBackgroundColor
        activityIndicator.color = UIColor.white
    }

    private func applyDarkerTheme() {
        navigationToolBar.barTintColor = UIColor.black
        view.backgroundColor = UIColor.black
    }

    func modifyShellDesign() {
        webView.shouldUseShellShadow { useShell in
            if useShell {
                self.addShellShadow()
            } else {
                self.removeShellShadow()
            }
        }
    }

    // MARK: - Theme configs
    func addShellShadow() {
        webView.setShellShadow(true)
        navigationToolBar.clipsToBounds = false
    }

    func removeShellShadow() {
        webView.setShellShadow(true)
        navigationToolBar.clipsToBounds = true
    }

    // MARK: - Notifications Functions
    func askForNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { [weak self] granted, _  in
            guard let self = self else { return }
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
            webView.observe(\DEVWebView.canGoBack, options: [.new, .old], changeHandler: { _, _ in
                self.updateNavigationBar()
            }),
            webView.observe(\DEVWebView.canGoForward, options: [.new, .old], changeHandler: { _, _ in
                self.updateNavigationBar()
            }),
            webView.observe(\DEVWebView.url, options: [.new, .old], changeHandler: { _, _ in
                self.updateNavigationBar()
            })
        ]
    }

    private func updateNavigationBar() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        if let url = webView.url {
            webView.scrollView.isScrollEnabled = !(url.path.hasPrefix("/connect")) //Remove scroll if /connect view
        }
        modifyShellDesign()
    }

    private func setupVideoPlayer() {
        if videoPlayerView == nil {
            videoPlayerView = DEVAVPlayerView(frame: view.frame)
            videoPlayerView?.delegate = self
            view.addSubview(videoPlayerView!)
            videoPlayerView?.addAVPlayerViewController(mediaManager.getVideoPlayer(), parentView: view)
            videoPlayerView?.viewController?.didMove(toParent: self)
        } else {
            videoPlayerView?.animateCurrentState(state: .fullscreen)
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let reachability = Network.reachability
        guard let isNetworkReachable = reachability?.isReachable, isNetworkReachable else {
            errorBanner.show()
            return
        }
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.fetchUserStatus { status in
            self.activityIndicator.stopAnimating()
            self.modifyShellDesign()
            if status == "logged-in" {
                self.populateUserData()
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {

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
        } else if url.host != devToHost && navigationType.rawValue == 0 {
            performSegue(withIdentifier: DoAction.openExternalURL, sender: url)
            return .cancel
        } else {
            return .allow
        }
    }
}

// MARK: - webkit messagehandler protocol
extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "podcast":
            var delay = 0.0
            if let videoPlayerView = videoPlayerView {
                videoPlayerView.animateDismiss(direction: .down)
                delay = 0.7
            }

            // In the rare case the user is playing a video and the player needs to be dismissed before
            // engaging with the podcast player, we need to give the animateDismiss a head start to finish
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.mediaManager.handlePodcastMessage(message.body as? [String: String] ?? [:])
            }
        case "video":
            mediaManager.handleVideoMessage(message.body as? [String: String] ?? [:])
            setupVideoPlayer()
        case "haptic":
            guard let hapticType = message.body as? String else { return }
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
        default: ()
        }
    }
}

extension ViewController: DEVAVPlayerViewDelegate {
    func playerDismissed() {
        videoPlayerView?.removeFromSuperview()
        videoPlayerView = nil
        mediaManager.dismissPlayer()
        webView?.sendBridgeMessage(type: "video", message: [ "action": "pause" ])
    }
}
