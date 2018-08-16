//
//  DevWebViewController.swift
//  DEV
//
//  Created by Wahyu Sumartha Priya Dharma on 09.08.18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import WebKit

class DevWebViewController: UIViewController, DevWebViewLoadable {
    // MARK: - Public Properties
    var webURL: URL?
  
    // MARK: - Private Properties
    private var leftBarButtonItem: UIBarButtonItem?
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.color = .devBlue
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()
    
    let webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.translatesAutoresizingMaskIntoConstraints = false 
        return webView
    }()

    private var webViewLayoutConstraints: [NSLayoutConstraint] {
        return [
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: -44),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }
    
    private var activityIndicatorViewLayoutConstraints: [NSLayoutConstraint] {
        return [
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -44)
        ]
    }
   
    // MARK: - Public Methods
    override func viewDidLoad() {
        super.viewDidLoad()
     
        navigationController?.navigationBar.barTintColor = .creamColor

        setupLeftBarButtonItem()
        setupSubviews()
        setupWebView()
        startLoadingIndicator()
    }
    

    @objc func leftBarButtonItemTapped() {
        guard webView.canGoBack else { return }
        
        let currentScrollViewContentOffset = webView.scrollView.contentOffset
        webView.scrollView.setContentOffset(currentScrollViewContentOffset,
                                            animated: false)
        webView.goBack()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { //race condition hack
            self.leftBarButtonItem?.isEnabled = self.webView.canGoBack
            self.leftBarButtonItem?.tintColor = self.webView.canGoBack ? .black : .clear
        }
    }

    // MARK: - Private Methods
    private func setupSubviews() {
        view.addSubview(webView)
        view.addSubview(activityIndicatorView)
        
        let activeConstraints = webViewLayoutConstraints + activityIndicatorViewLayoutConstraints
        NSLayoutConstraint.activate(activeConstraints)
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.addObserver(self,
                            forKeyPath: "URL",
                            options: [.new, .old],
                            context: nil)
        if let url = webURL {
            webView.load(URLRequest(url: url))
        }
    }

    private func startLoadingIndicator() {
        activityIndicatorView.startAnimating()
    }
    
    private func stopLoadingIndicator() {
        activityIndicatorView.stopAnimating()
    }
    
    private func setupLeftBarButtonItem() {
        leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Back"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(leftBarButtonItemTapped))
        leftBarButtonItem?.tintColor = .clear 
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
}

// MARK: - WKNavigationDelegate
extension DevWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopLoadingIndicator()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        stopLoadingIndicator()
    }
}
