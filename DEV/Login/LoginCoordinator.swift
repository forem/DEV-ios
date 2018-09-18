//
//  LoginCoordinator.swift
//  DEV
//
//  Created by Jackson, Ceri-anne (Associate Software Developer) on 16/09/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit

protocol Coordinator: class {
    func start()
    func finish()
}

class LoginCoordinator: Coordinator {
    
    let viewController: UIViewController
    
    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func start() {
        login()
    }
    
    func finish() {
        reloadTabBarItems()
    }
    
    private func login() {
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        
        guard let loginViewController = storyboard.instantiateInitialViewController() as? LoginViewController else {
            return
        }
        
        loginViewController.loginCoordinator = self
        
        viewController.present(loginViewController, animated: true)
    }
    
    private func reloadTabBarItems() {
        
        guard let viewControllers = viewController.tabBarController?.viewControllers else {
            return
        }
        
        viewControllers.forEach {
            
            if let viewController = $0 as? CanReload {
                viewController.reload()
                return
            }
            
            if let navController = $0 as? UINavigationController {
                if let viewController = navController.viewControllers.first as? CanReload {
                    viewController.reload()
                }
            }
            
        }
    }
}
