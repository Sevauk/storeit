//
//  OfflineManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 13/10/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

class OfflineManager {
    
    static let shared = OfflineManager()
    
    private let fileManager = FileManager.default
    private let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    private let offlineDirectoryUrl: URL
    
    private init() {
		offlineDirectoryUrl = URL(fileURLWithPath: documents + "/offline_data")
		createDirectory(at: offlineDirectoryUrl)
    }
    
    private func createDirectory(at path: URL) {
        do {
            try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("ERROR: could not create directory with error: \(error)")
        }
    }
    
    private func buildUrl(for hash: String, at path: String, createIntermediates: Bool = false) -> URL {
        var baseUrl = URL(fileURLWithPath: offlineDirectoryUrl.absoluteString)
        let components = path.components(separatedBy: "/").dropLast()
        
        for component in components {
            baseUrl = baseUrl.appendingPathComponent(component)
        }
        
        if createIntermediates {
        	createDirectory(at: baseUrl)
        }
        
        return baseUrl.appendingPathComponent(hash)
    }
    
    func getHashes(at path: String) -> [String] {
        let baseUrl = offlineDirectoryUrl.appendingPathComponent(path)
        
        do {
            let content = try fileManager.contentsOfDirectory(at: baseUrl, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants,
                                                                                                                     .skipsHiddenFiles,
                                                                                                                     .skipsPackageDescendants])
            
            let contentWithoutDirectory = content.filter { file in
                !file.hasDirectoryPath
            }
            
            let hashes = contentWithoutDirectory.map { file in
                file.lastPathComponent
            }
            
           	return hashes
            
        } catch {
            print("ERROR: Could not find any content at path \(path)")
        }
        
        return []
    }
    
    func write(hash: String, to path: String, content: Data) {
        let fileUrl = buildUrl(for: hash, at: path, createIntermediates: true)
        
        do {
        	try content.write(to: fileUrl, options: .atomicWrite)
            print("SUCCESS: File with hash \(hash) created in offline data directory !")
        } catch {
    		print("ERROR: Could not create file with hash \(hash) in offline data directory")
        }
    }
    
    func getData(for hash: String, at path: String) -> Data? {
        let fileUrl = buildUrl(for: hash, at: path)
        let relativePath = fileUrl.relativePath
        
        return fileManager.contents(atPath: relativePath)
    }
    
    func move(hash: String, at oldPath: String, to newPath: String) {
        let oldFileUrl = buildUrl(for: hash, at: oldPath)
        let newFileUrl = buildUrl(for: hash, at: newPath, createIntermediates: true)

        do {
        	try fileManager.moveItem(at: oldFileUrl, to: newFileUrl)
            NavigationManager.shared.addToCurrentHashes(hash: hash)
            print("SUCCESS: File with hash \(hash) has been moved to its new location in offline data directory !")
        } catch {
            print("ERROR: Could not move file with hash \(hash) to its new location in offline data directory !")
        }
    }
    
    func remove(hash: String, at path: String) -> Bool {
        let fileUrl = buildUrl(for: hash, at: path)

        do {
            try fileManager.removeItem(at: fileUrl)
            print("SUCCESS: File with hash \(hash) removed from offline data directory !")
            
            return true
        } catch {
            print("ERROR: Could not remove file with hash \(hash) from offline data directory !")
            
            return false
        }
    }
    
    func contains(hash: String, at path: String) -> Bool {
        let fileUrl = buildUrl(for: hash, at: path)
        
        do {
            _ = try fileUrl.checkResourceIsReachable()
            return true
        } catch {
            print("ERROR: Could not find ressource !")
         	return false
        }
    }
    
    func clear() {
        do {
            try fileManager.removeItem(at: offlineDirectoryUrl)
            print("SUCCESS: offline data directory cleared !")
        } catch let error {
            print("ERROR: Could not clear offline directory data with error : \(error)")
        }
    }
}
