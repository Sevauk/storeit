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

enum Property {
    case metadata
    case ipfsHash
}

class NavigationManager {
    
    static let shared = NavigationManager()
    
    private let _rootDirTitle = "StoreIt"
    
    var rootDirTitle: String {
    	return _rootDirTitle
    }
    
    private var storeItSynchDir: [String: File]
    private var indexes: [String]
    
    private var items: [String]
    private var currentDirectory: [String: File]
    
    private var currentOfflineHashes: [String]
    
    var list: UITableView?
    var moveToolBar: UIToolbar?
    
	var movingOptions = MovingOptions()
    
    private init() {
        storeItSynchDir = [:]
        indexes = []
        currentDirectory = [:]
        items = []
        currentOfflineHashes = []
    }
    
    func set(with items: [String: File]) {
        storeItSynchDir = items
        currentDirectory = items
        self.items = Array(items.keys)
        updateCurrentHashes()
    }
    
    // MARK: NAVIGATION FUNCTIONS
    
    func go(to nextDir: File) -> String {
        let targetName = getName(for: nextDir)
        
        indexes.append(targetName)
        currentDirectory = getCurrentFiles()
        items = Array(nextDir.files.keys)
        updateCurrentHashes()
        
        return targetName
    }
    
    func goBack() {
        _ = indexes.popLast()
        currentDirectory = getCurrentFiles()
        items = Array(currentDirectory.keys)
        updateCurrentHashes()
    }
    
    // MARK: UPDATE TREE FUNCTIONS
    
    // If the update is on the current directory (the focused one on the list view), we need to refresh
    private func updateCurrentItems(fileName: String, updateElement: UpdateElement, indexes: [String]) -> Int {
        var index: Int = -1

        if (indexes == indexes) {
            switch updateElement.updateType {
                case .add:
                    if (!items.contains(fileName)) {
                        items.append(fileName)
                        currentDirectory[fileName] = updateElement.fileToAdd!
                        index = items.count - 1
                	}
                
                case .delete:
                    let orderedItems = getSortedItems()
                    let orderedIndex = orderedItems.index(of: fileName)
                    
                    if let unwrapOrderedIndex = orderedIndex {
                        index = unwrapOrderedIndex
                    }
                    
                    let tmpIndex = items.index(of: fileName)
                    
                    if let unwrapTmpIndex = tmpIndex {
                        items.remove(at: unwrapTmpIndex)
                        currentDirectory.removeValue(forKey: fileName)
                	}

            	case .rename:
                    let tmpIndex = items.index(of: fileName)

                    if (tmpIndex != nil) {
                        if let newFileName = updateElement.pathToRenameWith?.1.components(separatedBy: "/").last {
                            index = tmpIndex!
                            
                            // Remove old item
                            items.remove(at: index)
                            let file = currentDirectory.removeValue(forKey: fileName)
                            
                            // Add new item
                            items.insert(newFileName, at: index)
                            currentDirectory[newFileName] = file
                            currentDirectory[newFileName]?.path = (updateElement.pathToRenameWith?.1)!
                        }
                }
                
            	case .update: break // TODO
            }
        }
        return index
    }

	private func updatePaths(_ storeit: inout [String:File], newPath: String) {
		let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            if let fileName = storeit[key]?.path.components(separatedBy: "/").last {
                storeit[key]!.path = "\(newPath)/\(fileName)"
                
                if (storeit[key]!.isDir) {
                    updatePaths(&storeit[key]!.files, newPath: "\(newPath)/\(fileName)")
                }
            }
        }
    }
    
    private func insertUpdate(in storeit: inout [String:File], with updateElement: UpdateElement, at path: [String]) {
        let keys: [String] = Array(storeit.keys)
        
        for key in keys {
            if let firstElementOfPath = path.first {
                if (key == firstElementOfPath) {
                    insertUpdate(in: &storeit[key]!.files, with: updateElement, at: Array(path.dropFirst()))
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
                            updatePaths(&storeit[fileName]!.files, newPath: file.path)
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
                                updatePaths(&storeit[newName]!.files, newPath: newPath)
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
    
    func updateTree(with updateElement: UpdateElement) -> Int {
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
            
            insertUpdate(in: &storeItSynchDir, with: updateElement, at: splitPath)
            index = updateCurrentItems(fileName: splitPath.last!, updateElement: updateElement, indexes: Array(splitPath.dropLast()))
        }
        
        return index
    }
    
    // MARK: UTIL FUNCTIONS
    
    private func updateCurrentHashes() {
        currentOfflineHashes = OfflineManager.shared.getHashes(at: buildCurrentDirectoryPath())
    }
    
    func isOfflineActivated(for hash: String) -> Bool {
        return currentOfflineHashes.contains(hash)
    }
    
    func removeFromCurrentHashes(hash: String) {
        if let index = currentOfflineHashes.index(of: hash) {
            currentOfflineHashes.remove(at: index)
        }
    }
    
    func getSortedItems() -> [String] {
        return items.sorted()
    }
    
    func getName(for file: File) -> String {
        let url: URL = URL(fileURLWithPath: file.path)
        return url.lastPathComponent
    }
    
    func getFile(at indexPath: IndexPath) -> File? {
        let sortedItems = getSortedItems()
        let selectedRow: String = sortedItems[(indexPath as NSIndexPath).row]
        
        if let selectedFile = currentDirectory[selectedRow] {
            return selectedFile
        }
        
        return nil
    }
    
    func getFile(at path: String) -> File? {
        var components = path.components(separatedBy: "/").dropFirst()
        var cpyStoreItSynchDir: [String: File] = storeItSynchDir
        
        while (components.count != 1) {
            let first = components.first!
            cpyStoreItSynchDir = (cpyStoreItSynchDir[first]?.files)!
            components = components.dropFirst()
        }
        
        return cpyStoreItSynchDir[components.first!]
    }
    
    func getCurrentFiles() -> [String: File] {
        let cpyIndexes = indexes
        var cpyStoreItSynchDir: [String: File] = storeItSynchDir
        
        if (indexes.isEmpty == false) {
            for index in cpyIndexes {
                cpyStoreItSynchDir = (cpyStoreItSynchDir[index]?.files)!
            }
            return cpyStoreItSynchDir
        }
        
        return storeItSynchDir
    }
    
    func getFileInCurrentDir(at path: String) -> File? {
        let fileName = path.components(separatedBy: "/").last!
        return currentDirectory[fileName]
    }
    
    func buildCurrentDirectoryPath() -> String {
        return "/\(indexes.joined(separator: "/"))"
    }
    
    func buildPath(for fileName: String) -> String {
        var path = "/"
        
        if (indexes.isEmpty) {
            return path + fileName
        }
        
        path += "\(indexes.joined(separator: "/"))/\(fileName)"
        return path
    }

    func createDir(path: String, metadata: String, IPFSHash: String, files: [String:File]? = nil) -> File {
        let dir = File(path: path,
                       metadata: metadata,
                       IPFSHash: IPFSHash,
                       isDir: true,
                       files: (files == nil ? [:] : files!))
        return dir
    }
    
    func createFile(path: String, metadata: String, IPFSHash: String) -> File {
        let file = File(path: path,
                        metadata: metadata,
                        IPFSHash: IPFSHash,
                        isDir: false,
                        files: [:])
        return file
    }
    
    func isFileADir(at indexPath: IndexPath) -> Bool {
        if let selectedFile: File = getFile(at: indexPath) {
            return selectedFile.isDir
        }
        
        return false
    }
    
}
