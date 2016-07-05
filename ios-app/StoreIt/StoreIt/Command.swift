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
        self.uid = -1
        self.command = ""
        self.parameters = nil
    }
    
    init(uid: Int, command: String, parameters: T) {
        self.uid = uid
        self.command = command
        self.parameters = parameters
    }
    
    required init?(_ map: Map) {
        self.uid = -1
        self.command = ""
        self.parameters = nil
    }
    
    func mapping(map: Map) {
        uid <- map["uid"]
        command <- map["command"]
        parameters <- map["parameters"]
    }

}