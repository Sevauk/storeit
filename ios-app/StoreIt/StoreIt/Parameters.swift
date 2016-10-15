//
//  Parameters.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class JoinParameters: Mappable {
    
    var authType: String
    var accessToken: String
    
    init() {
        authType = ""
        accessToken = ""
    }
    
    init(authType: String, accessToken: String) {
        self.authType = authType
        self.accessToken = accessToken
    }
    
    required init?(map: Map) {
        authType = ""
        accessToken = ""
    }
    
    func mapping(map: Map) {
        authType <- map["authType"]
        accessToken <- map["accessToken"]
    }
    
}

class FmovParameters: Mappable {
    
    var src: String
    var dest: String
    
    init() {
        src = ""
        dest = ""
    }
    
    init(src: String, dest: String) {
        self.src = src
        self.dest = dest
    }
    
    required init?(map: Map) {
        src = ""
        dest = ""
    }
    
    func mapping(map: Map) {
        src <- map["src"]
        dest <- map["dest"]
    }
}

class FdelParameters: Mappable {
    
    var files: [String]
    
    init() {
        files = []
    }
    
    init(files: [String]) {
        self.files = files
    }
    
    required init?(map: Map) {
        files = []
    }
    
    func mapping(map: Map) {
        files <- map["files"]
    }
}

class DefaultParameters: Mappable {
   
    var files: [File]
    
    init() {
        files = []
    }
    
    init(files: [File]) {
        self.files = files
    }
    
    required init?(map: Map) {
        files = []
    }
    
    func mapping(map: Map) {
        files <- map["files"]
    }
}
