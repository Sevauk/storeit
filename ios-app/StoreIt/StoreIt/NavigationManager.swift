//
//  NavigationManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

typealias src = String
typealias dest = String

enum UpdateType {
    case ADD
    case DELETE
    case RENAME
    case UPDATE
}

enum Property {
    case Metadata
    case IPFSHash
}

class MovingOptions {
    var isMoving: Bool = false
    var src: String?
    var dest: String?
    var file: File?
}


struct UpdateElement {
    
    let updateType: UpdateType
    var isMoving = false
    
    var fileToAdd: File? = nil
    var pathToDelete: String? = nil
    var pathToRenameWith: (src, dest)? = nil
    var propertyToUpdate: (Property, File)? = nil
    
    init(file: File, isMoving: Bool) {
        updateType = UpdateType.ADD
        fileToAdd = file
        self.isMoving = isMoving
    }
    
    init(path: String) {
     	updateType = UpdateType.DELETE
        pathToDelete = path
        
    }
    
    init(src: String, dest: String) {
        updateType = UpdateType.RENAME
        pathToRenameWith = (src, dest)
    }
    
    init(property: Property, file: File) {
        updateType = UpdateType.UPDATE
        propertyToUpdate = (property, file)
    }
}


class NavigationManager {
    
    let rootDirTitle: String
    
    private var storeItSynchDir: [String: File]
    private var indexes: [String]
    
    private var items: [String]
    private var currentDirectory: [String: File]
    
    var list: UITableView?
    var moveToolBar: UIToolbar?
    
	var movingOptions = MovingOptions()
    
    init(rootDirTitle: String, allItems: [String: File]) {
        self.rootDirTitle = rootDirTitle
        self.storeItSynchDir = allItems
        self.indexes = []
        self.currentDirectory = allItems
        self.items = Array(allItems.keys)
    }
    
    func setItems(allItems: [String: File]) {
        self.storeItSynchDir = allItems
        self.currentDirectory = allItems
        self.items = Array(allItems.keys)
    }
    
    func getSortedItems() -> [String] {
        return self.items.sort()
    }
    
    // If the update is on the current directory (the focused one on the list view), we need to refresh
    private func updateCurrentItems(fileName: String, updateElement: UpdateElement, indexes: [String]) -> Int {
        var index: Int = -1

        if (indexes == self.indexes) {
            switch updateElement.updateType {
                case .ADD:
                    if (!self.items.contains(fileName)) {
                        self.items.append(fileName)
                        self.currentDirectory[fileName] = updateElement.fileToAdd!
                        index = self.items.count - 1
                	}
                
                case .DELETE:
                    let orderedItems = self.getSortedItems()
                    let orderedIndex = orderedItems.indexOf(fileName)
                    
                    if let unwrapOrderedIndex = orderedIndex {
                        index = unwrapOrderedIndex
                    }
                    
                    let tmpIndex = self.items.indexOf(fileName)
                    
                    if let unwrapTmpIndex = tmpIndex {
                        self.items.removeAtIndex(unwrapTmpIndex)
                        self.currentDirectory.removeValueForKey(fileName)
                	}

            	case .RENAME:
                    let tmpIndex = items.indexOf(fileName)

                    if (tmpIndex != nil) {
                        if let newFileName = updateElement.pathToRenameWith?.1.componentsSeparatedByString("/").last {
                            index = tmpIndex!
                            
                            // Remove old item
                            self.items.removeAtIndex(index)
                            let file = self.currentDirectory.removeValueForKey(fileName)
                            
                            // Add new item
                            self.items.insert(newFileName, atIndex: index)
                            self.currentDirectory[newFileName] = file
                            self.currentDirectory[newFileName]?.path = (updateElement.pathToRenameWith?.1)!
                        }
                }
                
            	case .UPDATE: break // TODO
            }
        }
        return index
    }
    
    func buildCurrentDirectoryPath() -> String {
        return "/\(self.indexes.joinWithSeparator("/"))"
    }

    func buildPath(fileName: String) -> String {
        var path = "/"
        
        if (indexes.isEmpty) {
            return path + fileName
        }
        
        path += "\(self.indexes.joinWithSeparator("/"))/\(fileName)"
        return path
    }
    
    func getFileObjectsAtIndex() -> [String: File] {
        let cpyIndexes = self.indexes
        var cpyStoreItSynchDir: [String: File] = self.storeItSynchDir
        
        if (indexes.isEmpty == false) {
            for index in cpyIndexes {
                cpyStoreItSynchDir = (cpyStoreItSynchDir[index]?.files)!
            }
            return cpyStoreItSynchDir
        }
        
        return self.storeItSynchDir
    }
    
    func getFileObjInCurrentDir(path: String) -> File? {
        let fileName = path.componentsSeparatedByString("/").last!
        return currentDirectory[fileName]
    }
    
    func getFileObjByPath(path: String) -> File? {
        var components = path.componentsSeparatedByString("/").dropFirst()
        var cpyStoreItSynchDir: [String: File] = self.storeItSynchDir

        while (components.count != 1) {
            let first = components.first!
            cpyStoreItSynchDir = (cpyStoreItSynchDir[first]?.files)!
            components = components.dropFirst()
        }

        return cpyStoreItSynchDir[components.first!]
    }
    
    private func rebuildTree(newFile: File, currDir: [String:File], path: [String]) -> [String:File] {
        var newTree: [String:File] = [:]
        let keys: [String] = Array(currDir.keys)
        
        for key in keys {
            let firstElementOfPath = path.first!
            
            if (key == firstElementOfPath) {
         		newTree[key] = File(path: currDir[key]!.path, metadata: currDir[key]!.metadata, IPFSHash: currDir[key]!.IPFSHash, isDir: currDir[key]!.isDir,
         		                    files: rebuildTree(newFile, currDir: currDir[key]!.files, path: Array(path.dropFirst())))
            } else {
                newTree[key] = currDir[key]
            }
        }
        
        if (path.count == 1) {
            newTree[path.first!] = newFile
        }
        
        return newTree
    }
    
    private func updateFilePathsAfterRename(inout storeit: [String:File], newPath: String) {
		let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            if let fileName = storeit[key]?.path.componentsSeparatedByString("/").last {
                storeit[key]!.path = "\(newPath)/\(fileName)"
                
                if (storeit[key]!.isDir) {
                    self.updateFilePathsAfterRename(&storeit[key]!.files, newPath: "\(newPath)/\(fileName)")
                }
            }
        }
    }
    
    private func insertUpdateInTree(inout storeit: [String:File], updateElement: UpdateElement, path: [String]) {
        let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            if let firstElementOfPath = path.first {
                if (key == firstElementOfPath) {
                    insertUpdateInTree(&storeit[key]!.files, updateElement: updateElement, path: Array(path.dropFirst()))
                }
            }
        }
        
        if (path.count == 1) {
            let fileName = path.first!
            
            switch updateElement.updateType {
                case .ADD:
                    storeit[fileName] = updateElement.fileToAdd!
                    if let file = storeit[fileName] {
                        // We need to change the path of the subdir
                        if (file.isDir && updateElement.isMoving) {
                            self.updateFilePathsAfterRename(&storeit[fileName]!.files, newPath: file.path)
                        }
                    }
                case .DELETE:
                    storeit.removeValueForKey(fileName)
                case .RENAME:
                    let file = storeit.removeValueForKey(fileName)
                    
                    if let newPath = updateElement.pathToRenameWith?.1 {
                        if let newName = newPath.componentsSeparatedByString("/").last {
                            storeit[newName] = file
                            storeit[newName]!.path = newPath
                            
                            // We need to change the path of the subdir
                            if (storeit[newName]!.isDir) {
                                self.updateFilePathsAfterRename(&storeit[newName]!.files, newPath: newPath)
                            }
                        }
                    }
            	case .UPDATE:
                    if let propertyToUpdate = updateElement.propertyToUpdate {
                        if (propertyToUpdate.0 == Property.IPFSHash) {
                            storeit[fileName]?.IPFSHash = propertyToUpdate.1.IPFSHash
                        } else if (propertyToUpdate.0 == Property.Metadata) {
                            storeit[fileName]?.metadata = propertyToUpdate.1.metadata
                        }
                    }
            }
        }
    }
    
    func updateTree(updateElement: UpdateElement) -> Int {
        let path: String?
        
        switch updateElement.updateType {
            case .ADD:
            	path = updateElement.fileToAdd?.path
            case .DELETE:
            	path = updateElement.pathToDelete
            case .RENAME:
            	path = updateElement.pathToRenameWith?.0
        	case .UPDATE:
            	path = updateElement.propertyToUpdate?.1.path
        }
        
        var index = -1
        
        if let unwrapPath = path {
            let splitPath = Array(unwrapPath.componentsSeparatedByString("/").dropFirst())
            
            self.insertUpdateInTree(&self.storeItSynchDir, updateElement: updateElement, path: splitPath)
            index = self.updateCurrentItems(splitPath.last!, updateElement: updateElement, indexes: Array(splitPath.dropLast()))
        }
        
        return index
    }
    
    func getSelectedFileAtRow(indexPath: NSIndexPath) -> File {
        let sortedItems = self.getSortedItems()
        let selectedRow: String = sortedItems[indexPath.row]
        let selectedFile: File = self.currentDirectory[selectedRow]!
        
        return selectedFile
    }
    
    func isSelectedFileAtRowADir(indexPath: NSIndexPath) -> Bool {
        let selectedFile: File = self.getSelectedFileAtRow(indexPath)
        return selectedFile.isDir
    }
    
    func getTargetName(target: File) -> String {
        let url: NSURL = NSURL(fileURLWithPath: target.path)
        return url.lastPathComponent!
    }
    
    func goToNextDir(target: File) -> String {
        let targetName = self.getTargetName(target)
        
        self.indexes.append(targetName)
        self.currentDirectory = self.getFileObjectsAtIndex()
        self.items = Array(target.files.keys)
        
        return targetName
    }
    
    func goPreviousDir() {
        self.indexes.popLast()
        self.currentDirectory = self.getFileObjectsAtIndex()
        self.items = Array(self.currentDirectory.keys)
    }
    
}