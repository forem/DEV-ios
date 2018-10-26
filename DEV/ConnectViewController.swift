import Foundation
import UIKit
import WebKit
class ConnectViewController: BaseWebViewController, WKNavigationDelegate, CanReload {
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!

    @IBAction func buttonTapped(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.scrollView.setContentOffset(self.webView.scrollView.contentOffset, animated: false)
            self.webView.goBack()
        }
    }
    
    func reload() {
        webView.reload()
    }

    override func viewDidLoad() {
        webView.navigationDelegate = self
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new, .old], context: nil)
        webView.scrollView.isScrollEnabled = false
        webView.customUserAgent = "DEV-Native-iOS"
        if let authenticationURL = DevServiceURL.authentication.fullURL {
            webView.load(URLRequest.init(url: authenticationURL))
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
