//
//  Parameters.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class ReponseParameters: Mappable {
    var home: File?
    var accessToken: String?
    
    init() {
        home = File()
        accessToken = ""
    }
    
    init(home: File, accessToken: String) {
        self.home = home
        self.accessToken = accessToken
    }
    
    required init?(map: Map) {
        home = File()
        accessToken = ""
    }
    
    func mapping(map: Map) {
        home <- map["home"]
        accessToken <- map["accessToken"]
    }
}

class SubsParameters: Mappable {
   
    var email: String
    var password: String
    
    init() {
        email = ""
        password = ""
    }
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    required init?(map: Map) {
        email = ""
        password = ""
    }
    
    func mapping(map: Map) {
        email <- map["email"]
        password <- map["password"]
    }
}

class Auth: Mappable {
    
    var type: String
    var accessToken: String
    
    init() {
        type = ""
        accessToken = ""
    }
    
    init(type: String, accessToken: String) {
        self.type = type
        self.accessToken = accessToken
    }
    
    required init?(map: Map) {
        type = ""
        accessToken = ""
    }
    
    func mapping(map: Map) {
        type <- map["type"]
        accessToken <- map["accessToken"]
    }
}

class JoinParameters: Mappable {
    
    var hosting: [String]
    var auth: Auth
    
    init() {
        hosting = []
        auth = Auth()
    }
    
    init(authType: String, accessToken: String) {
        auth = Auth(type: authType, accessToken: accessToken)
        hosting = []
    }
    
    required init?(map: Map) {
        hosting = []
        auth = Auth()
    }
    
    func mapping(map: Map) {
        auth <- map["auth"]
        hosting <- map["hosting"]
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
