import Foundation
import UIKit
import WebKit
class NotificationsViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!

    @IBAction func buttonTapped(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.scrollView.setContentOffset(self.webView.scrollView.contentOffset, animated: false)
            self.webView.goBack()
        }
    }
    
    
    override func viewDidLoad() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.addObserver(self, forKeyPath: "URL", options: [.new, .old], context: nil)
        if let url = URL(string: "https://dev.to/notifications?rand="+MainHelper.randomString(length: 10)) {
            webView.load(URLRequest.init(url: url))
        }
        
        self.Activity.startAnimating()
        self.Activity.hidesWhenStopped = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        manageBackButton()
    }
    
    func manageBackButton(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { //race condition hack
            if self.webView.canGoBack {
                self.leftButton?.isEnabled = true
                self.leftButton.tintColor = UIColor.black
            } else {
                self.leftButton?.isEnabled = false
                self.leftButton.tintColor = UIColor.clear
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }

    
}
