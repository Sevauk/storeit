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
    
    fileprivate var plist: Plist?
    fileprivate let path: String
    
    init() {
		
        let rootPath = NSSearchPathForDirectoriesInDomains(Foundation.FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]
        let plistPathInDocument = rootPath + "/storeit_data.plist"
        let fileManager = Foundation.FileManager.default
        
        if (!fileManager.fileExists(atPath: plistPathInDocument)){
            plist = nil
            
        } else {
            plist = Plist(path: plistPathInDocument)
        }
        
        self.path = plistPathInDocument
    }
    
    func addValueForKey(_ key: String, value: String) {
        let data: NSMutableDictionary
        
        if (plist != nil) {
        	data = NSMutableDictionary(contentsOfFile: self.path)!
        } else {
            data = NSMutableDictionary()
        }
        
        data.setObject(value, forKey: key as NSCopying)
        data.write(toFile: path, atomically: true)
        self.plist = Plist(path: path)
	}
    
    func getValueWithKey(_ key: String) -> String {
        return self.plist?[key].string ?? "None"
    }
}
