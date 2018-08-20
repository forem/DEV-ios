import Foundation
import UIKit
import WebKit
import Alamofire

class FirstViewController: RootTabBarViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!
    var initialized = false

    @IBAction func buttonTapped(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.scrollView.setContentOffset(self.webView.scrollView.contentOffset, animated: false)
            self.webView.goBack()
        }
    }
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        let textToShare = "Swift is awesome!  Check out this website about it!"
        
        if let myWebsite = webView.url {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        if !initialized {
            webView.addObserver(self, forKeyPath: "URL", options: [.new, .old], context: nil)
            getBadgeCounts()
            initialized = true
        }
        if let feedUrl = DevServiceURL.feed.fullURL {
            webView.load(URLRequest.init(url: feedUrl))
        }
        self.Activity.startAnimating()
        self.Activity.hidesWhenStopped = true
        webView.backForwardList.perform(Selector(("_removeAllItems")))
        
        self.tabBarController?.viewControllers?.forEach {
            let _ = $0.view
        }

    }
    
    override func refreshView() {
        //reset badge value
        self.tabBarItem.badgeValue = nil
        self.view.setNeedsDisplay()
        if let feedUrl = DevServiceURL.feed.fullURL {
            Activity.startAnimating()
            webView.load(URLRequest.init(url: feedUrl))
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        manageBackButton()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }
    
    func manageBackButton(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { //race condition hack
            self.leftButton?.isEnabled = self.webView.canGoBack
            self.leftButton?.tintColor = self.webView.canGoBack ? .black : .clear
        }
    }
    
    func getBadgeCounts(){
        requestNotificationsCount()
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(requestNotificationsCount), userInfo: nil, repeats: true)
        requestUnopenedChatChannels()
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(requestUnopenedChatChannels), userInfo: nil, repeats: true)
    }
    
    @objc func requestNotificationsCount(){
        Alamofire.request("https://dev.to/notifications/counts").response { response in
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                if utf8Text != "0" {
                    self.tabBarController?.viewControllers![2].tabBarItem.badgeValue = utf8Text
                }
            }
        }
    }
    
    @objc func requestUnopenedChatChannels(){
        Alamofire.request("https://dev.to/chat_channels?state=unopened").responseJSON { response in
            if let json = response.result.value {
                if (json as AnyObject).count > 0 {
                    self.tabBarController?.viewControllers![3].tabBarItem.badgeValue = String((json as AnyObject).count)
                }
            }
        }
    }
}
