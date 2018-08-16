import UIKit

class NotificationsViewController: DevWebViewController {
    
    override func viewDidLoad() {
        self.webURL = DevServiceURL.notification.fullURL
        super.viewDidLoad()
        self.title = "Notifications"
    }
    
}
