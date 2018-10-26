//
//  BaseWebViewController.swift
//  DEV
//
//  Created by Nathan Ansel on 10/26/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import WebKit

/// A simple base class used to simplifiy layout code for the WKWebView and its scroll view.
class BaseWebViewController: UIViewController {
	@IBOutlet weak var webView: WKWebView!
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// Every time the view's layout updates, adjust the scroll indicator's offsets approriately.
		// Add 6 to adjust for the nav bar appearance in the web view.
		webView.scrollView.scrollIndicatorInsets.top = view.safeAreaInsets.top + 6
	}
}
