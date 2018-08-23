import Foundation
import UIKit
import WebKit
class NewArticleViewController: RootTabBarViewController {

    @IBAction func buttonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let composeArticleURL = DevServiceURL.composeArticle.fullURL {
            webURL = composeArticleURL
            self.startLoadingIndicator()
            webView.load(URLRequest.init(url: composeArticleURL))
        }
    }
    
    override func refreshView() {
        //reset badge value
        self.tabBarItem.badgeValue = nil
        self.view.setNeedsDisplay()
        if let url = webURL {
            self.startLoadingIndicator()
            webView.load(URLRequest(url: url))
        } else {
            if let composeArticleURL = DevServiceURL.composeArticle.fullURL {
                self.startLoadingIndicator()
                webView.load(URLRequest.init(url: composeArticleURL))
            }
        }
    }

}
