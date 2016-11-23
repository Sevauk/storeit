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
    
    private var home: File
    
    private var indexes: [String]
    
    private var items: [String]
    private var currentDirectory: [String: File]
    
    private var currentOfflineHashes: [String]
    
    var list: UITableView?
    var moveToolBar: UIToolbar?
    
	var movingOptions = MovingOptions()
    
    private init() {
        //storeItSynchDir = [:]
        indexes = []
        currentDirectory = [:]
        items = []
        currentOfflineHashes = []
        home = File()
    }
    
    func set(home: File) {
    	self.home = home
        updateItems(with: home.files)
        list?.reloadData()
    }
    
    // MARK: NAVIGATION FUNCTIONS
    
    func go(to nextDir: File) -> String {
        let targetName = getName(for: nextDir)
        
        indexes.append(targetName)
        currentDirectory = getCurrentFiles()
        items = Array(nextDir.files.keys)
        
        return targetName
    }
    
    func goBack() {
        _ = indexes.popLast()
        currentDirectory = getCurrentFiles()
        items = Array(currentDirectory.keys)
    }
    
    // MARK: UTIL FUNCTIONS
    
    func updateCurrentHashes() {
        currentOfflineHashes = OfflineManager.shared.getHashes(at: buildCurrentDirectoryPath())
        print("Current offline hashes updated : \(currentOfflineHashes)")
    }
    
    func isOfflineActivated(for hash: String) -> Bool {
        return currentOfflineHashes.contains(hash)
    }
    
    func removeFromCurrentHashes(hash: String) {
        if let index = currentOfflineHashes.index(of: hash) {
            currentOfflineHashes.remove(at: index)
        }
    }
    
    func addToCurrentHashes(hash: String) {
        currentOfflineHashes.append(hash)
    }
    
    func getSortedItems() -> [String] {
        return items.sorted()
    }
    
    func getName(for file: File) -> String {
        let url: URL = URL(fileURLWithPath: file.path)
        return url.lastPathComponent
    }
    
    func getName(forPath path: String) -> String? {
        if let fileName = path.components(separatedBy: "/").last {
            return fileName
        }
        
        return nil
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
        var cpyStoreItSynchDir: [String: File] = home.files
        
        while (components.count != 1) {
            let first = components.first!
            cpyStoreItSynchDir = (cpyStoreItSynchDir[first]?.files)!
            components = components.dropFirst()
        }
        
        return cpyStoreItSynchDir[components.first!]
    }
    
    func getCurrentFiles() -> [String: File] {
        let cpyIndexes = indexes
        var cpyStoreItSynchDir: [String: File] = home.files
        
        if (indexes.isEmpty == false) {
            for index in cpyIndexes {
                cpyStoreItSynchDir = (cpyStoreItSynchDir[index]?.files)!
            }
            return cpyStoreItSynchDir
        }
        
        return home.files
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
    
    
    /*
 	** MARK: UPDATE TREE FUNCTIONS
 	*/
    
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
    
    private func updateItems(with items: [String: File]) {
        currentDirectory = items
        self.items = Array(currentDirectory.keys).sorted()
    }
    
    private func update(atPath path: String) {
        // Check if file is on current view before ...
        
        let components = path.components(separatedBy: "/")
            .dropFirst()
            .dropLast()
        
        let indexes = Array(components)
        
        if (indexes != self.indexes) {
            return
        }
        
        print("File is on current view, updating ...")
        
        // Update list data source
        
        if self.indexes.isEmpty {
            updateItems(with: home.files)
        } else {
            var subFiles = home.files
            
            for index in self.indexes {
                if let fileObj = subFiles[index] {
                    subFiles = fileObj.files
                }
            }
            
            updateItems(with: subFiles)
        }
        
        list?.reloadData()
    }
    
    // Get recursively the last parent File OBJ in given path
    private func getLastParentFile(synchDir: inout [String: File],
                                    path: String,
                                    parentFile: ((inout File) -> ()),
                                    fileNotFound: (() -> ())) {
        
        let components = path.components(separatedBy: "/")
        
        if let firstComponent = components.first {
            if let _ = synchDir[firstComponent] {
                
                // Parent File OBJ found
                if components.count == 2 {
                    parentFile(&synchDir[firstComponent]!)
                } else {
                    let recomposedPath = components
                        .dropFirst() // drop parent
                        .joined(separator: "/")
                    
                    // Go deeper in sync dir to found last parent
                    getLastParentFile(synchDir: &synchDir[firstComponent]!.files,
                                      path: recomposedPath,
                                      parentFile: parentFile,
                                      fileNotFound: fileNotFound)
                }
                
            } else {
                fileNotFound()
            }
        }
    }
    
    // Return reference of the last parent File OBJ in callback
    private func getLastParentFile(forPath path: String,
                           foundFile: (inout File) -> (),
                           fileNotFound: () -> ()) {
        
        let pathComponents = path.components(separatedBy: "/").dropFirst()
        
        // root
        if pathComponents.count == 1 {
            foundFile(&home)
        }
        // subdir
        else {
            getLastParentFile(synchDir: &home.files,
                              path: pathComponents.joined(separator: "/"),
                              parentFile: { file in foundFile(&file)},
                              fileNotFound: { _ in fileNotFound()})
        }
    }
    
    private func getLastParentFile(forPath path: String, completion: (File) -> ()) {
        getLastParentFile(forPath: path,
                          foundFile: { parent in completion(parent)},
                          fileNotFound: { _ in })
    }
    
    func delete(paths: [String]) {
        for path in paths {
            getLastParentFile(forPath: path) { parent in
                if let fileName = getName(forPath: path) {
                    parent.files.removeValue(forKey: fileName)
                    update(atPath: path)
                }
            }
        }
    }
    
    func add(files: [File], isMoving: Bool = false) {
        for file in files {
            getLastParentFile(forPath: file.path) { parent in
                if let fileName = getName(forPath: file.path) {
                    parent.files[fileName] = file
                    
                    // Rename path of subdirs/files if target is a moving dir
                    if isMoving && file.isDir && parent.files[fileName] != nil {
                        updatePaths(&parent.files[fileName]!.files, newPath: file.path)
                    }
                    
                    update(atPath: file.path)
                }
            }
        }
    }
    
    func move(file: File, from src: String) {
        delete(paths: [src])
        add(files: [file], isMoving: true)
        
        movingOptions = MovingOptions()
        update(atPath: file.path)

        moveToolBar?.isHidden = true
        
        OfflineManager.shared.move(hash: file.IPFSHash, at: src, to: file.path)
    }
    
    func update(files: [File]) {
        for file in files {
            getLastParentFile(forPath: file.path) { parent in
                if let fileName = getName(forPath: file.path) {
                    
                    if (file.IPFSHash != "") {
                        parent.files[fileName]?.IPFSHash = file.IPFSHash
                    }
                    
                    if (file.metadata != "") {
                        parent.files[fileName]?.metadata = file.metadata
                    }
                    
                    update(atPath: file.path)
                }
            }
        }
    }
    
    func rename(from src: String, to dest: String) {
        getLastParentFile(forPath: src) { parent in
            if let oldFileName = getName(forPath: src),
                let newFileName = getName(forPath: dest) {
                
                let file = parent.files.removeValue(forKey: oldFileName)
                
                parent.files[newFileName] = file
                parent.files[newFileName]?.path = dest

                // Rename path of subdirs/files if target is a dir
               	if parent.files[newFileName]!.isDir {
                     updatePaths(&parent.files[newFileName]!.files, newPath: dest)
                }
                
                update(atPath: dest)
            }
        }
    }
}
