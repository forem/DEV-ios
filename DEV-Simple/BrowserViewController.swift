import Foundation
import UIKit
import WebKit
class BrowserViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!

    var destinationUrl: URL?
    
    @IBAction func buttonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func safariButtonTapped(_ sender: Any) {
        openInBrowser()
    }
    
    override func viewDidLoad() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        let url = URL(string: "https://github.com")!
        webView.load(URLRequest(url: destinationUrl ?? URL(string: "https://github.com")!))
    }
    
    func openInBrowser() {
        if let url = webView.url {
            UIApplication.shared.open(url, options: [:])
        }
    }
}
