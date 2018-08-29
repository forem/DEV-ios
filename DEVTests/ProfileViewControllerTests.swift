//
//  ProfileViewControllerTests.swift
//  DEVTests
//
//  Created by Jackson, Ceri-anne (Associate Software Developer) on 29/08/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import XCTest
@testable import DEV

class ProfileViewControllerTests: XCTestCase {

    var profileViewController: ProfileViewController?
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
    }
    
    func testURLWithUsername() {
    
        guard let profileViewController = profileViewController else {
            XCTFail("Failed to instantiate Profile View Controller from storyboard")
            return
        }
        
        profileViewController.username = "testAccountName"
        let _ = profileViewController.view
        
        guard let url = profileViewController.webView.url else {
            XCTFail("Expected webView url to be non-nil")
            return
        }
        
        XCTAssertTrue(url.absoluteString.contains("https://dev.to/testAccountName"))
        
    }
    
    func testURLWithNoUsername() {
        
        guard let profileViewController = profileViewController else {
            XCTFail("Failed to instantiate Profile View Controller from storyboard")
            return
        }
        
        let _ = profileViewController.view

        guard let url = profileViewController.webView.url else {
            XCTFail("Expected webView url to be non-nil")
            return
        }
        
        XCTAssertTrue(url.absoluteString.contains("https://dev.to/ben"))
        
    }
    
}
