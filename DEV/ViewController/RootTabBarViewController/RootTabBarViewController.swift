//
//  RootTabBarViewController.swift
//  DEV
// 
//  Created by Jacob on 8/20/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import WebKit

class RootTabBarViewController: UIViewController, DevWebViewLoadable {
    let webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    var webViewLayoutConstraints: [NSLayoutConstraint] {
        return [
            webView.topAnchor.constraint(equalTo: self.navigationController?.navigationBar.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: self.navigationController?.navigationBar.trailingAnchor ?? view.trailingAnchor),
            webView.leadingAnchor.constraint(equalTo: self.navigationController?.navigationBar.leadingAnchor ?? view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }
    
    @IBOutlet var leftBarButtonItem: UIBarButtonItem?
    @IBOutlet var activityIndicatorView : UIActivityIndicatorView!
    
    var webURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tabBar = self.tabBarController {
            tabBar.delegate = self
        }
        setupWebView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.backForwardList.perform(Selector(("_removeAllItems")))
    }
    
    func refreshView() {
        fatalError("Subclass must implement")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.manageBackButton()
    }
    
    func manageBackButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { //race condition hack
            self.leftBarButtonItem?.isEnabled = self.webView.canGoBack
            self.leftBarButtonItem?.tintColor = self.webView.canGoBack ? .black : .clear
        }
    }
    
    @IBAction func leftBarButtonItemTapped() {
        guard webView.canGoBack else { return }
        
        let currentScrollViewContentOffset = webView.scrollView.contentOffset
        webView.scrollView.setContentOffset(currentScrollViewContentOffset,
                                            animated: false)
        webView.goBack()
    }
    
    func startLoadingIndicator() {
        activityIndicatorView.startAnimating()
    }
    
    func stopLoadingIndicator() {
        activityIndicatorView.stopAnimating()
    }
    
    
    
    //MARK - Private methods
    private func setupWebView() {
        webView.navigationDelegate = self
        webView.addObserver(self,
                            forKeyPath: "URL",
                            options: [.new, .old],
                            context: nil)
        if let url = webURL {
            webView.load(URLRequest(url: url))
        }
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(webView, belowSubview: activityIndicatorView)
        NSLayoutConstraint.activate(webViewLayoutConstraints)
    }
}

//MARK: - UITabeBarControllerDelegate
extension RootTabBarViewController : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let selectedController = tabBarController.selectedViewController, selectedController == viewController {
            self.refreshView()
            return false
        }
        return true
    }
}

// MARK: - WKNavigationDelegate
extension RootTabBarViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopLoadingIndicator()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        stopLoadingIndicator()
    }
}
