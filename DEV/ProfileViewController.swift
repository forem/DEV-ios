import Foundation
import UIKit
import WebKit
class ProfileViewController: UIViewController, WKNavigationDelegate, CanReload {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!

    var username: String? {
        didSet {
            reload()
        }
    }

    @IBAction func buttonTapped(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.scrollView.setContentOffset(self.webView.scrollView.contentOffset, animated: false)
            self.webView.goBack()
        }
    }
    
    func reload() {
        if let username = username, let profileURL = DevServiceURL.profile(username: username).fullURL {
            webView.load(URLRequest.init(url: profileURL))
        }
    }
    
    override func viewDidLoad() {
        leftButton.tintColor = .clear
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new, .old], context: nil)
        webView.customUserAgent = "DEV-Native-iOS"
        if let username = username, let profileURL = DevServiceURL.profile(username: username).fullURL {
            webView.load(URLRequest.init(url: profileURL))
        }
        
        self.Activity.startAnimating()
        self.Activity.hidesWhenStopped = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        leftButton?.isEnabled = webView.canGoBack
        leftButton?.tintColor = webView.canGoBack ? .black : .clear
    }
   
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }

    
}
