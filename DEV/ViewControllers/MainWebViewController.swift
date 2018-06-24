import Foundation
import UIKit
import WebKit

class MainWebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        if let url = URL(string: "https://www.dev.to") {
            webView.load(URLRequest.init(url: url))
        }
    }

}
