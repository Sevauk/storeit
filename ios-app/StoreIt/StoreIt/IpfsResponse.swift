//
//  IpfsResponse.swift
//  StoreIt
//
//  Created by Romain Gjura on 29/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class IpfsAddResponse: Mappable {
    
    var name: String
    var hash: String
    
    init() {
        self.name = ""
        self.hash = ""
    }
    
    init(name: String, hash: String) {
        self.name = name
        self.hash = hash
    }
    
    required init?(_ map: Map) {
        self.name = ""
        self.hash = ""
    }
    
    func mapping(map: Map) {
        name <- map["Name"]
        hash <- map["Hash"]
    }
    
}