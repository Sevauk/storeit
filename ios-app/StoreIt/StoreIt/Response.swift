//
//  Response.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class Response : Mappable {
    
    var code: String
    var text: String
    var commandUid: Int
    var command: String
    var parameters: [String:File]?
    
    init() {
        self.code = ""
        self.text = ""
        self.command = ""
        self.commandUid = -1
        self.parameters = nil
    }
    
    init(code: String, text: String, commandUid: Int, command: String, parameters: [String: File]) {
        self.code = code
        self.text = text
        self.commandUid = commandUid
        self.command = command
        self.parameters = parameters
    }
    
    required init?(_ map: Map) {
        self.code = ""
        self.text = ""
        self.command = ""
        self.commandUid = -1
        self.parameters = nil
    }
    
    func mapping(map: Map) {
        code <- map["code"]
        text <- map["text"]
        commandUid <- map["commandUid"]
        command <- map["command"]
        parameters <- map["parameters"]
    }
    
}