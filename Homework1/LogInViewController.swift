//
//  LogInViewController.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 6/23/21.
//

import UIKit
import BCryptSwift
class LogInViewController: UIViewController {

    @IBAction func registerBtnPressed(_ sender: Any) {
        // Register new user with those credentials to FirebaseService.firebaseService
        let username = usernameTxtField.text ?? ""
        let pass = passTxtField.text ?? ""
        let salt = BCryptSwift.generateSalt()
        let passHash = BCryptSwift.hashPassword(pass, withSalt: salt)
        let defaults = UserDefaults.standard
        
        // popup alert to choose Role
//        let role = "Helper"
        let role = "Helper"
        // Main is to register with google
        // right now register it to FirebaseService.firebaseService and create a new user
        defaults.setValue(true, forKey: "userLogIn")
        defaults.setValue([username, role, passHash], forKey: "userCredentials")
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func loginBtnPressed(_ sender: Any) {
        let defaults = UserDefaults.standard
        let username = usernameTxtField.text ?? ""
        let pass = passTxtField.text ?? ""
        print("Auth : \(username)")
        authenticateUser(username: username, pass: pass, completion: { (authUser, helper) in
            if authUser{
                defaults.setValue(true, forKey: "userLogIn")
                var role = ""
                if helper {
                    role = "Helper"
                    let loggedInUser = FirebaseService.firebaseService.getHelperCollection().document(username)
                    loggedInUser.setData(["deviceToken": FirebaseService.firebaseService.deviceToken], merge: true)
                }
                else {
                    role = "Elder"
                    let loggedInUser = FirebaseService.firebaseService.getElderCollection().document(username)
                    loggedInUser.setData(["deviceToken": FirebaseService.firebaseService.deviceToken], merge: true)
                }
                print("Final role is \(role)")
                
                // Save device token to FirebaseService.firebaseService
                
                defaults.setValue([username, role], forKey: "userCredentials")
                self.navigationController?.popViewController(animated: true)
            } else {
                print("Notifiy unsuccesfull login for \(helper ? "helper" : "elder")")
            }
        })
    }
    
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var usernameTxtField: UITextField!
    @IBOutlet weak var passTxtField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func authenticateUser(username: String, pass: String, completion: @escaping (Bool, Bool) -> Void) -> Void{
        if username == "" || username.isEmpty || pass == "" || pass.isEmpty {
            // alert or validation
            completion(false, false)
        }
        else {
            // Main goal is to aut  henticate with Google Auth
            // check FirebaseService.firebaseService for the user with that username if pass hash matches
            // get pass hash for that user
            FirebaseService.firebaseService.getUserPass(username: username) { (passHash, isHelper, userExists) in
                if userExists {
                    let passEntry = self.passTxtField.text ?? ""
                    let auth = BCryptSwift.verifyPassword(passEntry, matchesHash: passHash) ?? false
                    if (auth){
                        print("Verified")
                        completion(true, isHelper)
                    }
                    else { completion(false, isHelper) }
                } else {
                    print("Wrong username for \(isHelper ? "helper" : "elder") !!!")
                    completion(false, isHelper)
                    }
                }
        }
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
