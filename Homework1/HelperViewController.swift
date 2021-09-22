//
//  HelperViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/23/21.
//

import UIKit
enum SPPermissionsOpener {
    
    static func openSettings() {
        DispatchQueue.main.async {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Lab05 - Settings opened: \(success)")
                    })
                } else {
                    UIApplication.shared.openURL(settingsUrl as URL)
                }
            } else {
                print("Lab05 - Settings not opened")
            }
        }
    }
}

class HelperViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let logOut = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        
        navigationItem.rightBarButtonItems = [logOut]
    }
    
    @objc func logout(){
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: "userLogIn")
        defaults.removeObject(forKey: "userCredentials")
        self.navigationController?.popToRootViewController(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    
}
