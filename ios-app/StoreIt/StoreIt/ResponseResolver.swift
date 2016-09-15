//
//  ResponseResolver.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class ResponseResolver : Mappable {
    
    var command: String
    var uid: Int
    
    required init?(_ map: Map) {
        self.command = ""
        self.uid = -1
    }
    
    func mapping(_ map: Map) {
        command <- map["command"]
        uid <- map["uid"]
    }
}
