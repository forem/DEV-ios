import Foundation
import UIKit
import WebKit
class NewArticleViewController: BaseWebViewController, WKNavigationDelegate {
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!

    @IBAction func buttonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        webView.customUserAgent = "DEV-Native-iOS"
        if let composeArticleURL = DevServiceURL.composeArticle.fullURL {
            webView.load(URLRequest.init(url: composeArticleURL))
        }
        
        self.Activity.startAnimating()
        self.Activity.hidesWhenStopped = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }

}
