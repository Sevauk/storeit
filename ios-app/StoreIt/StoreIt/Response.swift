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
    
    var code: Int
    var text: String
    var commandUid: Int
    var command: String
    var parameters: [String:File]?
    
    init() {
        code = -1
        text = ""
        command = ""
        commandUid = -1
        parameters = nil
    }
    
    init(code: Int, text: String, commandUid: Int, command: String, parameters: [String: File]?) {
        self.code = code
        self.text = text
        self.commandUid = commandUid
        self.command = command
        self.parameters = parameters
    }
    
    required init?(map: Map) {
        code = -1
        text = ""
        command = ""
        commandUid = -1
        parameters = nil
    }
    
    func mapping(map: Map) {
        code <- map["code"]
        text <- map["text"]
        commandUid <- map["commandUid"]
        command <- map["command"]
        parameters <- map["parameters"]
    }
    
}
