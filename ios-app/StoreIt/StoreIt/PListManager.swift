//
//  PListManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 17/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import Plist

class PListManager {
    
    private static var plist: Plist?
    private static var path: String?
    
    init() {
        let rootPath = NSSearchPathForDirectoriesInDomains(Foundation.FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]
        let plistPathInDocument = rootPath + "/storeit_data.plist"
        let fileManager = Foundation.FileManager.default
        
        if (!fileManager.fileExists(atPath: plistPathInDocument)){
            PListManager.plist = nil
            PListManager.path = nil
            
        } else {
            PListManager.plist = Plist(path: plistPathInDocument)
            PListManager.path = plistPathInDocument
        }
    }
    
    static func add(for key: String, value: String) {
        let data: NSMutableDictionary
        
        if let path = PListManager.path {
            if (plist != nil) {
                data = NSMutableDictionary(contentsOfFile: path)!
            } else {
                data = NSMutableDictionary()
            }
            
            data.setObject(value, forKey: key as NSCopying)
            data.write(toFile: path, atomically: true)
            
            self.plist = Plist(path: path)
        }
	}

    static func get(with key: String) -> String? {
        return self.plist?[key].string
    }
}
