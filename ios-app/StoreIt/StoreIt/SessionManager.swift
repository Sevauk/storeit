//
//  SessionManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 24/09/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

class SessionManager {
    
    private static let TOKEN = "token"
    private static let CONNECTION_TYPE = "connectionType"
    
    private static let defaults = UserDefaults.standard
    
    // MARK: setters
    
    static func set(token: String) -> Bool {
    	return KeychainWrapper.defaultKeychainWrapper.set(token, forKey: TOKEN)
    }
    
    static func removeToken() -> Bool {
        return KeychainWrapper.defaultKeychainWrapper.remove(key: TOKEN)
    }
    
    static func set(connectionType: ConnectionType) {
    	defaults.set(connectionType.rawValue, forKey: CONNECTION_TYPE)
    }
    
    static func removeConnectionType() {
        defaults.removeObject(forKey: CONNECTION_TYPE)
    }
    
    static func resetSession() {
        _ = removeToken()
        removeConnectionType()
    }
    
    // MARK: getters
    
    static func getToken() -> String? {
        return KeychainWrapper.defaultKeychainWrapper.string(forKey: TOKEN)
    }
    
    /*static func getConnectionType() -> ConnectionType {
        guard let connectionType = defaults.object(forKey: CONNECTION_TYPE) as? String else {
            return ConnectionType.none
        }

        return ConnectionType(rawValue: connectionType)!
    }*/
    
    static func getConnectionType() -> ConnectionType? {
        guard let connectionType = defaults.object(forKey: CONNECTION_TYPE) as? String else {
            return nil
        }
        
        return ConnectionType(rawValue: connectionType)
    }
}
