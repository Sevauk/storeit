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
    
    var isSynching = false
    
    init() {
        path = ""
        metadata = ""
        IPFSHash = ""
        files = [:]
        isDir = false
    }

    init(path: String, metadata: String, IPFSHash: String, isDir: Bool, files: [String: File]) {
        self.path = path
        self.metadata = metadata
        self.IPFSHash = IPFSHash
        self.isDir = isDir
        self.files = files
    }
    
   required init?(map: Map) {
        path = ""
    	metadata = ""
    	IPFSHash = ""
    	isDir = false
    	files = [:]
    }
    
    func mapping(map: Map) {
    	path <- map["path"]
        metadata <- map["metadata"]
        IPFSHash <- map["IPFSHash"]
        isDir <- map["isDir"]
        files <- map["files"]
    }
}
