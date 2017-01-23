//
//  ViewController.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import ObjectMapper
import FBSDKLoginKit
import GoogleSignIn

class LoginView: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    let CORNER_RADIUS: CGFloat = 4
    
    let networkManager = NetworkManager.shared
    
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var developerButton: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var fbButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fbButton.layer.cornerRadius = CORNER_RADIUS
        
        developerButton.layer.cornerRadius = CORNER_RADIUS
        
        googleButton.layer.cornerRadius = CORNER_RADIUS
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    @IBAction func developerLogin(_ sender: AnyObject) {
        OAuthServices.developerLogin(loginCallback: loginCallback, displayer: displayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: FACEBOOK
  
    @IBAction func fbLogin(_ sender: AnyObject) {
        let login: FBSDKLoginManager = FBSDKLoginManager()
        
        SessionManager.set(connectionType: ConnectionType.facebook)
        
        login.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            guard let result = result else {
                print(error ?? "")
                OAuthServices.logout()
                return
            }
            
            if result.isCancelled {
                print(result)
                OAuthServices.logout()
            }
                
            else {
                if result.grantedPermissions.contains("email"){
                    _ = SessionManager.set(token: result.token.tokenString)
                    OAuthServices.facebookLogin(loginCallback: self.loginCallback, displayer: self.displayer)
                }
            }
        }
    }
    
    // MARK: GOOGLE
    
    @IBAction func googleLogin(_ sender: AnyObject) {
    	GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!,
              present viewController: UIViewController!) {
        SessionManager.set(connectionType: ConnectionType.google)
        present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!,
              dismiss viewController: UIViewController!) {
        SessionManager.removeConnectionType()
        dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        OAuthServices.googleSignIn(signIn,
                                     didSignInFor: user,
                                     withError: error,
                                     loginCallback: loginCallback,
                                     displayer: displayer)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        OAuthServices.logout()
    }

    // MARK: Utils
    
    func displayer(message: String) {
        displayAlert(withMessage: message)
    }
    
    func loginCallback(success: Bool, message: String, goToLoginView: Bool) {
        print("[LoginView] logginCallback -> success \(success) with message \(message)")
        
        if success {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.shouldSupportAllOrientations = true
            
            performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
        } else {
            if (goToLoginView) {
                _ = navigationController?.popToRootViewController(animated: true)
            }
            
            OAuthServices.logout()
            displayAlert(withMessage: message)
        }
    }
    
}




