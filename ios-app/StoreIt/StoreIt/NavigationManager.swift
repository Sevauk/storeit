//
//  NavigationManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

enum UpdateType {
    case ADD
    case DELETE
}

struct UpdateElement {
    let fileToAdd: File?
    let pathToDelete: String?
    let updateType: UpdateType
    
    init(file: File) {
        fileToAdd = file
        pathToDelete = nil
        updateType = UpdateType.ADD
    }
    
    init(path: String) {
     	fileToAdd = nil
        pathToDelete = path
        updateType = UpdateType.DELETE
    }
}

class NavigationManager {
    
    let rootDirTitle: String
    
    private var storeItSynchDir: [String: File]
    private var indexes: [String]
    
    var items: [String]
    private var currentDirectory: [String: File]
    
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
    
    // If the update is on the current directory (the focused one on the list view), we need to refresh
    private func updateCurrentItems(fileName: String, updateElement: UpdateElement, indexes: [String]) -> Int {
        var index: Int = 0
        
        if (indexes == self.indexes) {
            switch updateElement.updateType {
                case .ADD:
                    self.items.append(fileName)
                    self.currentDirectory[fileName] = updateElement.fileToAdd!
                	index = self.items.count - 1
                case .DELETE:
                    let tmpIndex = items.indexOf(fileName)
                    
                    if (tmpIndex != nil) {
                        index = tmpIndex!
                        self.items.removeAtIndex(index)
                        self.currentDirectory.removeValueForKey(fileName)
                    }
                }
        }
        
        return index
    }

    func buildPath(fileName: String) -> String {
        var path = "/"
        
        if (indexes.isEmpty) {
            return path + fileName
        }
        
        path += "\(self.indexes.joinWithSeparator("/"))/\(fileName)"
        return path
    }
    
    func getFileObjectAtIndex() -> [String: File] {
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
    
    private func insertUpdateInTree(inout storeit: [String:File], updateElement: UpdateElement, path: [String]) {
        let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            let firstElementOfPath = path.first!
            
            if (key == firstElementOfPath) {
                insertUpdateInTree(&storeit[key]!.files, updateElement: updateElement, path: Array(path.dropFirst()))
            }
        }
        
        if (path.count == 1) {
            let fileName = path.first!
            
            switch updateElement.updateType {
                case .ADD:
                    storeit[fileName] = updateElement.fileToAdd!
                    
                case .DELETE:
                    storeit.removeValueForKey(fileName)
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
            }
        
        var index = 0
        
        if let unwrapPath = path {
            let splitPath = Array(unwrapPath.componentsSeparatedByString("/").dropFirst())
            
            self.insertUpdateInTree(&self.storeItSynchDir, updateElement: updateElement, path: splitPath)
            index = self.updateCurrentItems(splitPath.last!, updateElement: updateElement, indexes: Array(splitPath.dropLast()))
        }
        
        return index
    }
    
    func getSelectedFileAtRow(indexPath: NSIndexPath) -> File {
        let selectedRow: String = self.items[indexPath.row]
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
        self.currentDirectory = self.getFileObjectAtIndex()
        self.items = Array(target.files.keys)

        return targetName
    }
    
    func goPreviousDir() {
        self.indexes.popLast()
        self.currentDirectory = self.getFileObjectAtIndex()
        self.items = Array(self.currentDirectory.keys)
    }
    
}