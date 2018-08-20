//
//  RootTabBarViewController.swift
//  DEV
// 
//  Created by Jacob on 8/20/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit

class RootTabBarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tabBar = self.tabBarController {
            tabBar.delegate = self
        }
        
    }
    
    func refreshView() {
        self.view.setNeedsDisplay()
        //reset badge value
        self.tabBarItem.badgeValue = nil
    }
    
}

extension RootTabBarViewController : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let selectedController = tabBarController.selectedViewController, selectedController == viewController {
            self.refreshView()
            return false
        }
        return true
    }
}
