import Foundation
import UIKit
import WebKit
import Alamofire
import AlamofireImage

class FirstViewController: UIViewController, WKNavigationDelegate, CanReload {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftButton: UIBarButtonItem!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    @IBOutlet weak var Activity: UIActivityIndicatorView!
    var initialized = false
    
    var user: User? {
        didSet {
            updateProfileViewController()
        }
    }

    lazy var loginCoordinator = LoginCoordinator(self)

    @IBAction func buttonTapped(_ sender: Any) {
        if self.webView.canGoBack {
            self.webView.scrollView.setContentOffset(self.webView.scrollView.contentOffset, animated: false)
            self.webView.goBack()
        }
    }
    
    func reload() {
        webView.reload()
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
        leftButton.tintColor = .clear
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "DEV-Native-iOS"
        self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate // Needs to go in first loaded controller (this one)
        if !initialized {
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: [.new, .old], context: nil)
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        leftButton?.isEnabled = webView.canGoBack
        leftButton?.tintColor = webView.canGoBack ? .black : .clear
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
        
        let js = "document.getElementsByTagName('body')[0].getAttribute('data-user-status')"
        webView.evaluateJavaScript(js) { result, error in
            
            if let error = error {
                print("Error getting user data: \(error)")
            }
            
            if let jsonString = result as? String {
                if jsonString == "logged-in" {
                    print("Logged in")
                    self.populateUserData()
                } else if jsonString == "logged-out" {
                    print("Logged out")
                    self.loginCoordinator.start()
                }
            }
            
        }
        
    }

    func populateUserData() {
        
        let js = "document.getElementsByTagName('body')[0].getAttribute('data-user')"
        webView.evaluateJavaScript(js) { result, error in
            
            if let error = error {
                print("Error getting user data: \(error)")
            }
            
            if let jsonString = result as? String {
                if let user = try? JSONDecoder().decode(User.self, from: Data(jsonString.utf8)) {
                    self.user = user
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }
    
    func getBadgeCounts(){
        requestNotificationsCount()
        Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(requestNotificationsCount), userInfo: nil, repeats: true)
        requestUnopenedChatChannels()
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(requestUnopenedChatChannels), userInfo: nil, repeats: true)
    }
    
    @objc func requestNotificationsCount(){
        Alamofire.request("https://dev.to/notifications/counts").response { response in
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                if let num = Int(utf8Text) {
                    if num != 0  {
                        self.tabBarController?.viewControllers![2].tabBarItem.badgeValue = utf8Text
                        if self.tabBarController?.selectedViewController != self.tabBarController?.viewControllers![2] {
                            self.tabBarController?.viewControllers![2].view.setNeedsDisplay()
                            self.tabBarController?.viewControllers![2].viewDidLoad()
                        }
                    }
                }
            }
        }
    }
    
    @objc func requestUnopenedChatChannels(){
        Alamofire.request("https://dev.to/chat_channels?state=unopened").responseJSON { response in
            if let json = response.result.value {
                let num = (json as AnyObject).count
                if num ?? 0 > 0 {
                    self.tabBarController?.viewControllers![3].tabBarItem.badgeValue = String((json as AnyObject).count)
                    if self.tabBarController?.selectedViewController != self.tabBarController?.viewControllers![3] {
                        self.tabBarController?.viewControllers![3].view.setNeedsDisplay()
                        self.tabBarController?.viewControllers![3].viewDidLoad()
                    }
                }
            }
        }
    }
    
    func updateProfileViewController() {
        
        guard let viewControllers = self.tabBarController?.viewControllers else { return }
       
        guard let profileViewController = viewControllers.first(where: {
            $0 is ProfileViewController}) as? ProfileViewController else { return }
        
        if let username = user?.username {
            profileViewController.username = username
            
            setUserImage(forTab: profileViewController)
        }
    }

    func setUserImage(forTab profileViewController: UIViewController) {
        
        guard let profileImageUrl = self.user?.profileImage else { return }
        
        DispatchQueue.global(qos: .background).async {
            Alamofire.request(profileImageUrl).responseImage { response in
                
                if let image = response.result.value {
                    DispatchQueue.main.async {
                        let circularImage = self.scaleImageWithRenderingMode(imageToScale: image)
                        self.placeImageInTabBar(profileViewController, tabImage: circularImage)
                    }
                }
            }
        }
    }
    
    private func scaleImageWithRenderingMode(imageToScale: UIImage) -> UIImage {
        let size = CGSize(width: 24.0, height: 24.0)
        let scaledImage = imageToScale.af_imageScaled(to: size)
        let circularImage = scaledImage.af_imageRoundedIntoCircle()
        
        return circularImage.withRenderingMode(.alwaysOriginal)
    }
    
    private func placeImageInTabBar(_ profileViewController: UIViewController, tabImage: UIImage) {
        let customTabBarItem = UITabBarItem(title: "DEV.self", image: tabImage, selectedImage: tabImage)
        profileViewController.tabBarItem = customTabBarItem
    }
}
