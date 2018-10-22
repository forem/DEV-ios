//
//  AppDelegate.swift
//  DEV
//
//  Created by Ben Halpern on 6/8/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import Alamofire
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UITabBarItem.appearance().badgeColor = .blue //UIColor (red: 78.0, green: 87.0, blue: 239.0, alpha: 1.0) //rgb(78, 87, 239)
        let theViewController = self.window?.rootViewController
        theViewController?.view.backgroundColor = UIColor (red: 253.0/255.0, green: 249.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        
        //Set the background fetch interval to check for notifications (check user setting in the future)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {
        // Check for new data.
        Alamofire.request("https://dev.to/notifications/counts").response { response in
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                if let num = Int(utf8Text) {
                    if num != 0  {
                        let content = UNMutableNotificationContent()
                        content.title = "New DEV.to Articles!"
                        content.subtitle = "New DEV.to Articles!"
                        content.body = "There are new articles waiting."
                        content.badge = num as NSNumber
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                        let request = UNNotificationRequest(identifier: "timerdone", content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        completionHandler(.newData)
                    } else {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        completionHandler(.noData)
                    }
                }
            } else{
                completionHandler(.failed)
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let application = UIApplication.shared.delegate as! AppDelegate
        let tabbarController = application.window?.rootViewController as! UITabBarController
        let selectedController = tabbarController.selectedViewController
        if selectedController == viewController {
            viewController.view.setNeedsDisplay()
            viewController.viewDidLoad()
        }
        
        viewController.tabBarItem.badgeValue = nil // I assume this is a pretty cheap operation, so just calling it every time. We could call it conditionally too.
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let tabBarController = window?.rootViewController as? UITabBarController,
            let viewControllers = tabBarController.viewControllers {
            for viewController in viewControllers {
                if let notificationViewController = viewController as? NotificationsViewController {
                    tabBarController.selectedViewController = notificationViewController
                }
            }
        }
        
    }
    
}
