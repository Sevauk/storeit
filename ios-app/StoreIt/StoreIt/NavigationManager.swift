//
//  NavigationManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

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
    
    private func setItemsAndCheckIndexes(newElement: (String, File), indexes: [String]) -> Bool{
        // If the file to add is on the current directory (the focused one on the list view) == we need to refresh
        if (indexes == self.indexes) {
        	self.items.append(newElement.0)
            self.currentDirectory[newElement.0] = newElement.1

            return true
        }
        
        return false
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
    
    private func insertInTree(inout storeit: [String:File], newFile: File, path: [String]) {
        let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            let firstElementOfPath = path.first!
            
            if (key == firstElementOfPath) {
                insertInTree(&storeit[key]!.files, newFile: newFile, path: Array(path.dropFirst()))
            }
        }
        
        if (path.count == 1) {
            storeit[path.first!] = newFile
        }
    }
    
    func insertFileObject(file: File) -> Bool {
        let path = Array(file.path.componentsSeparatedByString("/").dropFirst())
        
        self.insertInTree(&self.storeItSynchDir, newFile: file, path: path)
        
        let needUpdate = self.setItemsAndCheckIndexes((path.last!, file), indexes: Array(path.dropLast()))
        
        return needUpdate
    }
    
    func updateFileObject() {
        
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