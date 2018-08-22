import Foundation
import UIKit
import WebKit
class ConnectViewController: RootTabBarViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let authenticationURL = DevServiceURL.authentication.fullURL {
            webURL = authenticationURL
            self.startLoadingIndicator()
            webView.load(URLRequest.init(url: authenticationURL))
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
            if let authenticationURL = DevServiceURL.authentication.fullURL {
                webURL = authenticationURL
                self.startLoadingIndicator()
                webView.load(URLRequest.init(url: authenticationURL))
            }
        }
    }

    
}
