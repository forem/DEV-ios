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
        viewController.devToURL = "test.html"
        super.setUp()
    }
    
    func testCustomUserAgent() {
        _ = viewController.view
        // Then the customerUserAgent it set correctly
        XCTAssertEqual(viewController.webView.customUserAgent, "DEV-Native-ios")
    }

    func testPolicyForNavigationAction() {

        let nonDev      = URL(string: "https://someOtherUrl")!
        let aboutBlank  = URL(string: "about:blank")!
        let twitterAuth = URL(string: "https://github.com/login/extra/test/stuff")!
        let githubAuth  = URL(string: "https://api.twitter.com/oauth/extra/test/stuff")!
        let devTo       = URL(string: "https://dev.to")!
        let mail        = URL(string: "mailto:test@test.com")!
        
        XCTAssertEqual(viewController.navigationPolicy(url: nonDev,      navigationType: .linkActivated), .cancel)
        XCTAssertEqual(viewController.navigationPolicy(url: nonDev,      navigationType: .backForward),   .allow)
        XCTAssertEqual(viewController.navigationPolicy(url: aboutBlank,  navigationType: .linkActivated), .allow)
        XCTAssertEqual(viewController.navigationPolicy(url: twitterAuth, navigationType: .backForward),   .allow)
        XCTAssertEqual(viewController.navigationPolicy(url: githubAuth,  navigationType: .linkActivated), .allow)
        XCTAssertEqual(viewController.navigationPolicy(url: devTo,       navigationType: .backForward),   .allow)
        XCTAssertEqual(viewController.navigationPolicy(url: mail,        navigationType: .linkActivated), .cancel)

    }
}
