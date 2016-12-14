//
//  UidFactory.swift
//  StoreIt
//
//  Created by Romain Gjura on 05/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

class UidFactory {
    
    typealias Command = String
    typealias Uid = Int
    
    static var uid: Uid = 0
    
    private static var waintingForResponse: [Uid:Command] = [:]
    private static var objectsForUid: [Uid:AnyObject] = [:]
    
    static func addNewWaitingCommand(_ command: Command, objects: AnyObject?) {
        waintingForResponse[uid] = command
        objectsForUid[uid] = objects
        uid += 1
    }
    
    static func isWaitingForReponse(_ uid: Uid) -> Bool {
        return waintingForResponse.keys.contains(uid)
    }
    
    // No checks needed, called after "isWaitingForReponse"
    static func getCommandNameForUid(_ uid: Uid) -> Command {
        return waintingForResponse[uid]!
    }
    
    static func getObjectForUid(_ uid: Uid) -> AnyObject {
        return objectsForUid[uid]!
    }
}
