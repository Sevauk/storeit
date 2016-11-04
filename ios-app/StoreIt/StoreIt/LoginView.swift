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
    
    let networkManager = NetworkManager.sharedInstance
    
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var developerButton: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    @IBOutlet weak var fbButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fbButton.layer.cornerRadius = CORNER_RADIUS
        //fbButton.center = view.center
        
        developerButton.layer.cornerRadius = CORNER_RADIUS
        //developerButton.center = view.center
        
        googleButton.layer.cornerRadius = CORNER_RADIUS
        //googleButton.center = view.center
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        if let connectionType = SessionManager.getConnectionType() {
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().signInSilently()
            } else if connectionType == ConnectionType.facebook {
                processFacebookLogin()
            } else if connectionType == ConnectionType.developer {
                processDeveloperLogin()
            }
        }
    }
    
    @IBAction func developerLogin(_ sender: AnyObject) {
        processDeveloperLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: FACEBOOK

    func processFacebookLogin() {
        
    	// refresh token here
        
        networkManager.initConnection(loginFunction: loginFunction, logoutFunction: logoutToLoginView)
        
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    @IBAction func fbLogin(_ sender: AnyObject) {
        let login: FBSDKLoginManager = FBSDKLoginManager()
        
        SessionManager.set(connectionType: ConnectionType.facebook)
        
        login.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            guard let result = result else {
                print(error)
                self.logout()
                return
            }
            
            if result.isCancelled {
                print(result)
                self.logout()
            }
                
            else {
                if result.grantedPermissions.contains("email"){
                    _ = SessionManager.set(token: result.token.tokenString)
                    self.processFacebookLogin()
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
        self.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!,
              dismiss viewController: UIViewController!) {
        SessionManager.removeConnectionType()
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            print("[LoginView] \(error)")
            SessionManager.removeConnectionType()
            return
        }
        
        _ = SessionManager.set(token: user.authentication.accessToken)
        SessionManager.set(connectionType: ConnectionType.google)
        
        networkManager.initConnection(loginFunction: loginFunction, logoutFunction: logoutToLoginView)
        
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        logout()
    }

    // MARK: Utils
    
    func processDeveloperLogin() {
        networkManager.initConnection(loginFunction: loginDeveloperFunction, logoutFunction: logoutToLoginView)
        SessionManager.set(connectionType: ConnectionType.developer)
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    @IBAction func logoutSegue(_ segue: UIStoryboardSegue) {
        logout()
    }
    
    func loginDeveloperFunction() {
        networkManager.joinDeveloper { _ in
            print("[LoginView] JOIN as developer succeeded")
        }
    }
    
    func loginFunction() {
        if let token = SessionManager.getToken() {
            if let connectionType = SessionManager.getConnectionType() {
                	networkManager.join(connectionType.rawValue, accessToken: token) { _ in
                    print("[LoginView] JOIN succeeded")
                }
            }
        }
    }
    
    func logout() {
        if let connectionType = SessionManager.getConnectionType() {
            print("[LoginView] Logging out...")
            
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().disconnect()
            } else if connectionType == ConnectionType.facebook {
                FBSDKLoginManager().logOut()
            }
            
            networkManager.close()
            SessionManager.resetSession()
        }
    }
    
    func logoutToLoginView() {
        _ = self.navigationController?.popToRootViewController(animated: true)
        logout()
    }

}




