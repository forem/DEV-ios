import Foundation
import UIKit
import WebKit
class DashboardViewController: RootTabBarViewController {
    
    @IBAction func buttonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dashboardURL = DevServiceURL.dashboard.fullURL {
            webURL = dashboardURL
            self.startLoadingIndicator()
            webView.load(URLRequest.init(url: dashboardURL))
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
            if let dashboardURL = DevServiceURL.dashboard.fullURL {
                self.startLoadingIndicator()
                webView.load(URLRequest.init(url: dashboardURL))
            }
        }
    }
    
}
