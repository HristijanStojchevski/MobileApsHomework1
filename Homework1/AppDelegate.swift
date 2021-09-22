//
//  AppDelegate.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/22/21.
//

import UIKit
import Firebase

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("token: \(deviceToken)")
        FirebaseService.firebaseService.deviceToken = deviceToken.hexString
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("error with registering for remote notifications")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .list, .banner])
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // Override point for customization after application launch.
      FirebaseApp.configure()
//
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        //define Actions -- Change this for this application
        let checkItem  = UNNotificationAction(identifier: "openItem", title: "Open", options: [.foreground])
        let ignoreItem = UNNotificationAction(identifier: "ignoreItem", title: "Ignore", options: [.destructive])

        let openMenu  = UNNotificationAction(identifier: "openMenu", title: "Make a review", options: [.foreground])
        let ignoreNotif = UNNotificationAction(identifier: "refuseReview", title: "Not this time", options: [.destructive])

        //Add actions to category
        let itemUpdateCategory = UNNotificationCategory(identifier: "itemUpdateCategory", actions: [checkItem, ignoreItem], intentIdentifiers: [], options: [])
        let reviewCategory = UNNotificationCategory(identifier: "reviewCategory", actions: [openMenu, ignoreNotif], intentIdentifiers: [], options: [])

        //Add the category to notification framework
        UNUserNotificationCenter.current().setNotificationCategories([itemUpdateCategory, reviewCategory])

        
        
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

