//
//  ViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/22/21.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    var loggedIn: Bool = false
    var isElder: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        fbService.getElderCollection().getDocuments { (snapshot, error) in
//            if error == nil && snapshot != nil {
//                for document in snapshot!.documents{
//                    print(document.data())
//                }
//            }  
//        }
        
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "userLogIn") {
            loggedIn = true
            if let userCreds = defaults.stringArray(forKey: "userCredentials"){
                let username = userCreds[0]
                let role = userCreds[1]
                if role == "Elder" {
                    isElder = true
                }
                print("Auto log in user \(username)")
                //Google auth
                
                
                let profile = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(profileTapped))
                let logOut = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
                
                
                navigationItem.rightBarButtonItems = [profile, logOut]
            }
        }
        else{
            loggedIn = false
            let logIn = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(login))

            navigationItem.rightBarButtonItems = [logIn]
        }
        // If not logged in show log in btn
        
        
        // If logged in show Profile btn
        
    }
    @objc func logout(){
        FirebaseService.firebaseService.getLoggedInUser { (userRef) in
            userRef.setValue("loggedOff", forKey: "deviceToken")
        }
        loggedIn = false
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: "userLogIn")
        defaults.removeObject(forKey: "userCredentials")
        let logIn = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(login))
        navigationItem.rightBarButtonItems = [logIn]
        
    }
    
    @objc func login(){
        let vc = storyboard?.instantiateViewController(identifier: "LogInViewController") as! LogInViewController
        self.navigationController?.pushViewController(vc, animated: true)
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func profileTapped(){
        
        // if elder
        if isElder {
            let vc = storyboard?.instantiateViewController(identifier: "ElderProfileViewController") as! ProfileViewController
            self.present(vc, animated: true, completion: nil)
        } else {
            let vc2 = storyboard?.instantiateViewController(identifier: "HelperProfileViewController") as! HelperDashViewController
            self.present(vc2, animated: true, completion: nil)
        }
//        self.navigationController?.pushViewController(vc, animated: true)
        // if helper
//        let vc2 = storyboard?.instantiateViewController(identifier: "HelperProfileViewController") as! HelperDashViewController
//        self.present(vc2, animated: true, completion: nil)
    }
    
    @IBAction func openHelperController(_ sender: Any) {
        if loggedIn && !isElder{
        let vc = storyboard?.instantiateViewController(identifier: "HelperTabBarController") as! HelperViewController
//        self.present(vc, animated: true, completion: nil)
        self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func openElderController(_ sender: Any) {
        if loggedIn && isElder {
        let vc = storyboard?.instantiateViewController(identifier: "ElderCategoriesViewController") as! ElderCategoriesViewController
//        self.present(vc, animated: true, completion: nil)
        self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent?.restorationIdentifier == "MapTabViewController" {
            print("Got view with id \(String(describing: parent?.restorationIdentifier))")
            	
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "userLogIn") {
            loggedIn = true
            if let userCreds = defaults.stringArray(forKey: "userCredentials"){
//                let username = userCreds[0]
//                let pass = userCreds[1]
                let role = userCreds[1]
                if role == "Elder" {
                    isElder = true
                }
                else {
                    isElder = false
                }
                //Google auth
                
                
                let profile = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(profileTapped))
                let logOut = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
                
                
                navigationItem.rightBarButtonItems = [profile, logOut]
            }
        }
        else{
            loggedIn = false
            let logIn = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(login))

            navigationItem.rightBarButtonItems = [logIn]
        }
    }
}

