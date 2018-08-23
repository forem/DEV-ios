import UIKit

class NotificationsViewController: RootTabBarViewController {
    
    override var webViewLayoutConstraints: [NSLayoutConstraint] {
        return [
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webURL = DevServiceURL.notification.fullURL
        self.title = "Notifications"
    }
    
    override func refreshView() {
        if let url = webURL {
            self.startLoadingIndicator()
            webView.load(URLRequest(url: url))
        } else {
            if let url = DevServiceURL.notification.fullURL {
                self.startLoadingIndicator()
                webView.load(URLRequest(url: url))
            }
        }
    }
    
}
