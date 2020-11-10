//
//  ViewControllerTests.swift
//  DEV-SimpleTests
//
//  Created by Ceri-anne Jackson on 13/11/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import XCTest

@testable import DEV_Simple

class ViewControllerTests: XCTestCase {

    var viewController: ViewController!
   
    override func setUp() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = mainStoryboard.instantiateInitialViewController() as? ViewController
        super.setUp()
    }
    
    func testCustomUserAgent() {
        _ = viewController.view
        
        let promise = expectation(description: "User Agent expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let usesForemWebViewUserAgent = self.viewController.webView.customUserAgent?.contains("ForemWebView")
            XCTAssertTrue(usesForemWebViewUserAgent ?? false)
            promise.fulfill()
        }
        wait(for: [promise], timeout: 10)
    }
    
    func testDevtoBaseUrl() {
        XCTAssertEqual(self.viewController.devToURL, "https://dev.to")
    }
}
