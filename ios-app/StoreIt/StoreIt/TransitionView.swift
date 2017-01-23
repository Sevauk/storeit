//
//  TransitionView.swift
//  StoreIt
//
//  Created by Romain Gjura on 26/11/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import UIKit
import FBSDKLoginKit
import GoogleSignIn

class TransitionView: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loading.startAnimating()

        navigationController?.isNavigationBarHidden = true
                
        if let connectionType = SessionManager.getConnectionType() {
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().signInSilently()
            } else if connectionType == ConnectionType.facebook {
                OAuthServices.facebookLogin(loginCallback: loginCallback, displayer: nil)
            } else if connectionType == ConnectionType.developer {
                OAuthServices.developerLogin(loginCallback: loginCallback, displayer: nil)
            }
        } else {
            performSegue(withIdentifier: "loginView", sender: nil)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loading.stopAnimating()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        OAuthServices.googleSignIn(signIn,
                                     didSignInFor: user,
                                     withError: error,
                                     loginCallback: loginCallback,
                                     displayer: nil)
    }
    
    func loginCallback(success: Bool, message: String, goToLoginView: Bool) {
        print("[LoginView] logginCallback -> success \(success) with message \(message)")
        
        if success {
            performSegue(withIdentifier: "autoLog", sender: nil)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.shouldSupportAllOrientations = true
        } else {
            performSegue(withIdentifier: "loginView", sender: nil)
            
            OAuthServices.logout()
            displayAlert(withMessage: message)
        }
    }
    
    @IBAction func logoutSegue(_ segue: UIStoryboardSegue) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldSupportAllOrientations = false
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        OAuthServices.logout()
    }
}
