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
    case add
    case delete
    case rename
    case update
}

enum Property {
    case metadata
    case ipfsHash
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


class NavigationManager {
    
    let rootDirTitle: String
    
    fileprivate var storeItSynchDir: [String: File]
    fileprivate var indexes: [String]
    
    fileprivate var items: [String]
    fileprivate var currentDirectory: [String: File]
    
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
    
    func setItems(_ allItems: [String: File]) {
        self.storeItSynchDir = allItems
        self.currentDirectory = allItems
        self.items = Array(allItems.keys)
    }
    
    func getSortedItems() -> [String] {
        return self.items.sorted()
    }
    
    // If the update is on the current directory (the focused one on the list view), we need to refresh
    fileprivate func updateCurrentItems(_ fileName: String, updateElement: UpdateElement, indexes: [String]) -> Int {
        var index: Int = -1

        if (indexes == self.indexes) {
            switch updateElement.updateType {
                case .add:
                    if (!self.items.contains(fileName)) {
                        self.items.append(fileName)
                        self.currentDirectory[fileName] = updateElement.fileToAdd!
                        index = self.items.count - 1
                	}
                
                case .delete:
                    let orderedItems = self.getSortedItems()
                    let orderedIndex = orderedItems.index(of: fileName)
                    
                    if let unwrapOrderedIndex = orderedIndex {
                        index = unwrapOrderedIndex
                    }
                    
                    let tmpIndex = self.items.index(of: fileName)
                    
                    if let unwrapTmpIndex = tmpIndex {
                        self.items.remove(at: unwrapTmpIndex)
                        self.currentDirectory.removeValue(forKey: fileName)
                	}

            	case .rename:
                    let tmpIndex = items.index(of: fileName)

                    if (tmpIndex != nil) {
                        if let newFileName = updateElement.pathToRenameWith?.1.components(separatedBy: "/").last {
                            index = tmpIndex!
                            
                            // Remove old item
                            self.items.remove(at: index)
                            let file = self.currentDirectory.removeValue(forKey: fileName)
                            
                            // Add new item
                            self.items.insert(newFileName, at: index)
                            self.currentDirectory[newFileName] = file
                            self.currentDirectory[newFileName]?.path = (updateElement.pathToRenameWith?.1)!
                        }
                }
                
            	case .update: break // TODO
            }
        }
        return index
    }
    
    func buildCurrentDirectoryPath() -> String {
        return "/\(self.indexes.joined(separator: "/"))"
    }

    func buildPath(_ fileName: String) -> String {
        var path = "/"
        
        if (indexes.isEmpty) {
            return path + fileName
        }
        
        path += "\(self.indexes.joined(separator: "/"))/\(fileName)"
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
    
    func getFileObjInCurrentDir(_ path: String) -> File? {
        let fileName = path.components(separatedBy: "/").last!
        return currentDirectory[fileName]
    }
    
    func getFileObjByPath(_ path: String) -> File? {
        var components = path.components(separatedBy: "/").dropFirst()
        var cpyStoreItSynchDir: [String: File] = self.storeItSynchDir

        while (components.count != 1) {
            let first = components.first!
            cpyStoreItSynchDir = (cpyStoreItSynchDir[first]?.files)!
            components = components.dropFirst()
        }

        return cpyStoreItSynchDir[components.first!]
    }
    
    fileprivate func rebuildTree(_ newFile: File, currDir: [String:File], path: [String]) -> [String:File] {
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
    
    fileprivate func updateFilePathsAfterRename(_ storeit: inout [String:File], newPath: String) {
		let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            if let fileName = storeit[key]?.path.components(separatedBy: "/").last {
                storeit[key]!.path = "\(newPath)/\(fileName)"
                
                if (storeit[key]!.isDir) {
                    self.updateFilePathsAfterRename(&storeit[key]!.files, newPath: "\(newPath)/\(fileName)")
                }
            }
        }
    }
    
    fileprivate func insertUpdateInTree(_ storeit: inout [String:File], updateElement: UpdateElement, path: [String]) {
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
                case .add:
                    storeit[fileName] = updateElement.fileToAdd!
                    if let file = storeit[fileName] {
                        // We need to change the path of the subdir
                        if (file.isDir && updateElement.isMoving) {
                            self.updateFilePathsAfterRename(&storeit[fileName]!.files, newPath: file.path)
                        }
                    }
                case .delete:
                    storeit.removeValue(forKey: fileName)
                case .rename:
                    let file = storeit.removeValue(forKey: fileName)
                    
                    if let newPath = updateElement.pathToRenameWith?.1 {
                        if let newName = newPath.components(separatedBy: "/").last {
                            storeit[newName] = file
                            storeit[newName]!.path = newPath
                            
                            // We need to change the path of the subdir
                            if (storeit[newName]!.isDir) {
                                self.updateFilePathsAfterRename(&storeit[newName]!.files, newPath: newPath)
                            }
                        }
                    }
            	case .update:
                    if let propertyToUpdate = updateElement.propertyToUpdate {
                        if (propertyToUpdate.0 == Property.ipfsHash) {
                            storeit[fileName]?.IPFSHash = propertyToUpdate.1.IPFSHash
                        } else if (propertyToUpdate.0 == Property.metadata) {
                            storeit[fileName]?.metadata = propertyToUpdate.1.metadata
                        }
                    }
            }
        }
    }
    
    func updateTree(_ updateElement: UpdateElement) -> Int {
        let path: String?
        
        switch updateElement.updateType {
            case .add:
            	path = updateElement.fileToAdd?.path
            case .delete:
            	path = updateElement.pathToDelete
            case .rename:
            	path = updateElement.pathToRenameWith?.0
        	case .update:
            	path = updateElement.propertyToUpdate?.1.path
        }
        
        var index = -1
        
        if let unwrapPath = path {
            let splitPath = Array(unwrapPath.components(separatedBy: "/").dropFirst())
            
            self.insertUpdateInTree(&self.storeItSynchDir, updateElement: updateElement, path: splitPath)
            index = self.updateCurrentItems(splitPath.last!, updateElement: updateElement, indexes: Array(splitPath.dropLast()))
        }
        
        return index
    }
    
    func getSelectedFileAtRow(_ indexPath: IndexPath) -> File {
        let sortedItems = self.getSortedItems()
        let selectedRow: String = sortedItems[(indexPath as NSIndexPath).row]
        let selectedFile: File = self.currentDirectory[selectedRow]!
        
        return selectedFile
    }
    
    func isSelectedFileAtRowADir(_ indexPath: IndexPath) -> Bool {
        let selectedFile: File = self.getSelectedFileAtRow(indexPath)
        return selectedFile.isDir
    }
    
    func getTargetName(_ target: File) -> String {
        let url: URL = URL(fileURLWithPath: target.path)
        return url.lastPathComponent
    }
    
    func goToNextDir(_ target: File) -> String {
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
