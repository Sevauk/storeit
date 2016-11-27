//
//  OAuthServices.swift
//  StoreIt
//
//  Created by Romain Gjura on 27/11/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import FBSDKLoginKit

class OAuthServices {
    
    class func developerLogin(loginCallback: @escaping (Bool, String, Bool) -> (),
                              displayer: ((String) -> ())?) {
        SessionManager.set(connectionType: ConnectionType.developer)
        _ = SessionManager.set(token: "developer")
        NetworkManager.shared.initConnection(loginHandler: loginCallback, displayer: displayer)
    }
    
    class func googleSignIn(_ signIn: GIDSignIn!,
                              didSignInFor user: GIDGoogleUser!,
                              withError error: Error!,
                              loginCallback: @escaping (Bool, String, Bool) -> (),
                              displayer: ((String) -> ())?) {
        
        if let error = error {
            print("[OAuthServices.onGoogleSignIn] \(error)")
            SessionManager.removeConnectionType()
            return
        }
        
        _ = SessionManager.set(token: user.authentication.accessToken)
        SessionManager.set(connectionType: ConnectionType.google)
        NetworkManager.shared.initConnection(loginHandler: loginCallback, displayer: displayer)
    }
    
    class func facebookLogin(loginCallback: @escaping (Bool, String, Bool) -> (), displayer: ((String) -> ())?) {
        // refresh token here
        NetworkManager.shared.initConnection(loginHandler: loginCallback, displayer: displayer)
    }
    
    class func logout() {
        if let connectionType = SessionManager.getConnectionType() {
            print("[LoginView] Logging out...")
            
            if connectionType == ConnectionType.google {
                GIDSignIn.sharedInstance().disconnect()
            } else if connectionType == ConnectionType.facebook {
                FBSDKLoginManager().logOut()
            }
            
            NetworkManager.shared.close()
            SessionManager.resetSession()
        }
    }
}
