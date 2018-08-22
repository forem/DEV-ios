import Foundation
import UIKit
import WebKit
class ProfileViewController: RootTabBarViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let profileURL = DevServiceURL.profile.fullURL {
            webURL = profileURL
            self.startLoadingIndicator()
            webView.load(URLRequest.init(url: profileURL))
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
            if let profileURL = DevServiceURL.profile.fullURL {
                self.startLoadingIndicator()
                webView.load(URLRequest.init(url: profileURL))
            }
        }
    }
}
