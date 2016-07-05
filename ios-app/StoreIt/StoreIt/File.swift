//
//  File.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class File: Mappable {
    
    var path: String
    var metadata: String
    var IPFSHash: String
    var isDir: Bool
    var files: [String: File]
    
    init() {
        self.path = ""
        self.metadata = ""
        self.IPFSHash = ""
        self.files = [:]
        self.isDir = false
    }

    init(path: String, metadata: String, IPFSHash: String, isDir: Bool, files: [String: File]) {
        self.path = path
        self.metadata = metadata
        self.IPFSHash = IPFSHash
        self.isDir = isDir
        self.files = files
    }
    
   required init?(_ map: Map) {
        self.path = ""
    	self.metadata = ""
    	self.IPFSHash = ""
    	self.isDir = false
    	self.files = [:]
    }
    
    func mapping(map: Map) {
    	path <- map["path"]
        metadata <- map["metadata"]
        IPFSHash <- map["IPFSHash"]
        isDir <- map["isDir"]
        files <- map["files"]
    }
}