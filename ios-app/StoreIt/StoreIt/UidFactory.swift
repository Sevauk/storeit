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
    
    var uid: Uid = 0
    var waintingForResponse: [Uid:Command] = [:]
    var objectsForUid: [Uid:AnyObject] = [:]
    
    func addNewWaitingCommand(_ command: Command, objects: AnyObject) {
        waintingForResponse[uid] = command
        objectsForUid[uid] = objects
        uid += 1
    }
    
    func isWaitingForReponse(_ uid: Uid) -> Bool {
        return waintingForResponse.keys.contains(uid)
    }
    
    // No checks needed, called after "isWaitingForReponse"
    func getCommandNameForUid(_ uid: Uid) -> Command {
        return waintingForResponse[uid]!
    }
    
    func getObjectForUid(_ uid: Uid) -> AnyObject {
        return objectsForUid[uid]!
    }
}
