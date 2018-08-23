import Foundation
import UIKit
import WebKit
class SearchViewController: RootTabBarViewController, UITextFieldDelegate {
    @IBOutlet weak var searchInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL(string: "https://dev.to/search?rand="+MainHelper.randomString(length: 10)) {
            self.webURL = url
            webView.load(URLRequest.init(url: url))
        }
        searchInput.delegate = self
        searchInput.returnKeyType = .search
        searchInput.text = ""
        self.startLoadingIndicator()
        webView.backForwardList.perform(Selector(("_removeAllItems")))

    }
    
    override func refreshView() {
        //reset badge value
        self.tabBarItem.badgeValue = nil
        self.view.setNeedsDisplay()
        
        if let  url = webURL {
            self.startLoadingIndicator()
            webView.load(URLRequest(url: url))
        } else {
            if let url = URL(string: "https://dev.to/search?rand="+MainHelper.randomString(length: 10)) {
                self.startLoadingIndicator()
                webView.load(URLRequest.init(url: url))
            }
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        guard let searchKeywordText = textField.text,
            !searchKeywordText.isEmpty
        else {
            // do not perform any search if text file is nil or empty
            textField.resignFirstResponder()
            return true
        }
        
        searchInput.endEditing(true)
       
        if let searchURL = DevServiceURL.search(parameter: searchKeywordText).fullURL {
            webView.load(URLRequest.init(url: searchURL))
        }
        
        textField.resignFirstResponder()

        self.manageBackButton()
       
        return true
    }

}
