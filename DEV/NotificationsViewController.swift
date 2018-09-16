import UIKit

class NotificationsViewController: DevWebViewController, CanReload {
    
    override func viewDidLoad() {
        self.webURL = DevServiceURL.notification.fullURL
        super.viewDidLoad()
        self.title = "Notifications"
    }
    
    func reload() {
        webView.reload()
    }
    
}
