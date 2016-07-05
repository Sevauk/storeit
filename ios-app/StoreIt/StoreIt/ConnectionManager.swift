//
//  ConnectionManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 05/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import p2_OAuth2

class ConnectionManager {
    
    let oauth2: OAuth2?
    
    init(connectionType: ConnectionType) {
        print("[ConnexionManager] Initializing a connexion of type \(connectionType)")
        
        switch connectionType {
            case .GOOGLE:
                oauth2 = OAuth2Google()
            	break
            
        	default:
            	oauth2 = nil
                break
    	}
        
        oauth2?.onFailureOrAuthorizeAddEvents()
    }
    
    func accessToken() -> String? {
        return self.oauth2?.accessToken()
    }
    
    func forgetTokens() {
        self.oauth2?.forgetTokens()
    }
    
    func handleRedirectUrl(url: NSURL) {
        self.oauth2?.handleRedirectUrl(url)
    }
    
    func authorize(context: AnyObject) {
        self.oauth2?.authorize(context)
    }
    
}