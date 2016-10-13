//
//  UpdateElement.swift
//  StoreIt
//
//  Created by Romain Gjura on 13/10/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

enum UpdateType {
    case add
    case delete
    case rename
    case update
}

struct UpdateElement {
    
    let updateType: UpdateType
    var isMoving = false
    
    var fileToAdd: File? = nil
    var pathToDelete: String? = nil
    var pathToRenameWith: (src, dest)? = nil
    var propertyToUpdate: (Property, File)? = nil
    
    init(file: File, isMoving: Bool) {
        updateType = UpdateType.add
        fileToAdd = file
        self.isMoving = isMoving
    }
    
    init(path: String) {
        updateType = UpdateType.delete
        pathToDelete = path
        
    }
    
    init(src: String, dest: String) {
        updateType = UpdateType.rename
        pathToRenameWith = (src, dest)
    }
    
    init(property: Property, file: File) {
        updateType = UpdateType.update
        propertyToUpdate = (property, file)
    }
}
