//
//  Command.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class Command<T: Mappable>: Mappable {
    
    var uid: Int
    var command: String
    var parameters: T?
    
    init() {
        uid = -1
        command = ""
        parameters = nil
    }
    
    init(uid: Int, command: String, parameters: T?) {
        self.uid = uid
        self.command = command
        self.parameters = parameters
    }
    
    required init?(map: Map) {
        uid = -1
        command = ""
        parameters = nil
    }
    
    func mapping(map: Map) {
        uid <- map["uid"]
        command <- map["command"]
        parameters <- map["parameters"]
    }

}
