//
//  FileManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper
import CryptoSwift

enum FileType: Int {
    case unknown = -1
	case directory
	case regularFile
    case link
}

class FileManager {
    
    fileprivate let fileManager = Foundation.FileManager.default
    
    let rootDirPath: String // storeit base directory
    let absoluteRootDirPath: String // storeit directory full path

    init(path: String) {
        let url: URL = URL(fileURLWithPath: path)
        self.rootDirPath = url.lastPathComponent
        self.absoluteRootDirPath = url.path
        
    }
    
     func getFilePathsInFileObject(_ file: File, paths: [String]) -> [String] {
        var newPaths = paths

        // Simple file or empty dir
        if (!file.isDir || (file.isDir && file.files.isEmpty)) {
            newPaths.append(file.path)
        }
        // Not empty dir
        else {
            for (_, file) in file.files {
                if file.isDir {
                    newPaths.append(contentsOf: getFilePathsInFileObject(file, paths: newPaths))
                } else {
                    newPaths.append(file.path)
                }
            }
        }
        
        return newPaths
    }
    
    func getSyncDirTree() -> [String: File] {
        return self.buildTree(self.rootDirPath)
    }
    
    func createDir(_ path: String, metadata: String, IPFSHash: String, files: [String:File]? = nil) -> File {
        let dir = File(path: path,
                       metadata: metadata,
                       IPFSHash: IPFSHash,
                       isDir: true,
                       files: (files == nil ? [:] : files!))
        return dir
    }
    
    func createFile(_ path: String, metadata: String, IPFSHash: String) -> File {
        let file = File(path: path,
                       metadata: metadata,
                       IPFSHash: IPFSHash,
                       isDir: false,
                       files: [:])
        return file
    }
    
    // Build recursively the tree of the root directory into a dictionnary
    fileprivate func buildTree(_ path: String) -> [String: File] {
        let files: [String] = getDirectoryContent(path)
        var nestedFiles: [String: File] = [String:File]()
        
        for file in files {
            let filePath = "\(path)/\(file)"
            let type = fileType(filePath)

            switch type {
                case .regularFile :
                    nestedFiles[file] = File(path: filePath,
                                             metadata: "",
                                             IPFSHash: "",
                                             isDir: false,
                                             files: [String:File]())
                case .directory :
                    nestedFiles[file] = File(path: filePath,
                                             metadata: "",
                                             IPFSHash: "",
                                             isDir: true,
                                             files: buildTree(filePath))
                default :
                    print("[FileManager] Error while building tree : file type doesn't exist.")
            }
        }
        return nestedFiles
    }
    
    fileprivate func fileType(_ path: String) -> FileType {
        var isDir : ObjCBool = false
        
        if (fileManager.fileExists(atPath: getFullPath(path), isDirectory: &isDir)) {
            if isDir.boolValue {
                return FileType.directory
            } else {
                return FileType.regularFile
            }
        }
        else {
            return FileType.unknown
        }
    }
    
    fileprivate func getDirectoryContent(_ path: String) -> [String] {
        let fullPath: String = getFullPath(path)
        
        do {
        	let dirContent = try fileManager.contentsOfDirectory(atPath: fullPath)
            return dirContent
        } catch {
            print("[FileManager] Error while getting file of \(fullPath) directory")
            return []
        }
    }
    
    fileprivate func getDirectoryNestedContent() -> [String] {
    	let dirContent = fileManager.enumerator(atPath: absoluteRootDirPath);
        var dirContentArray = [String]()
        
        for file in dirContent!.allObjects {
            dirContentArray += [file as! String]
        }
        
        return dirContentArray
    }
    
    // Concatenate absolute path and file path to get full path (ex: /path/to/dir/storeit + storeit/dir/file = /path/to/dir/storeit/dir/file)
    fileprivate func getFullPath(_ path: String) -> String {
        let parentURL: URL = NSURL(fileURLWithPath: absoluteRootDirPath).deletingLastPathComponent!
        let parent: String = parentURL.path
        return "\(parent)/\(path)"
    }
    
    fileprivate func sha256(_ path: String) -> String {
        let url: URL = URL(fileURLWithPath: getFullPath(path))
        let data: Data = try! Data(contentsOf: url)
        
        return data.sha256()!.toHexString()
    }

}
