//
//  IpfsManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 24/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import SwiftIpfsApi
import SwiftMultihash

class IpfsManager {
    
    private let ipfs: IpfsApi?
    private let host: String
    private let port: Int
    
    init?(host: String, port: Int) {
        do {
            self.host = host
            self.port = port
			self.ipfs = try IpfsApi(host: host, port: port)
        } catch let err as NSError {
            print("[IPFS] Error when initializing IFPS... (error: \(err))")
            return nil
        }
    }
    
    func get(hash: String, completionHandler: ([UInt8] -> Void)) {
        do {
        	let multihash = try fromB58String(hash)
        	try self.ipfs!.get(multihash, completionHandler: completionHandler)
        }
        catch let err as NSError { print("[IPFS.GET] error: \(err)") }
    }
    
    func add(filePath: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        let CRLF = "\r\n"
        let boundary = self.generateBoundaryString()
        
        let data = NSData(contentsOfURL: filePath)
        let fileName = filePath.lastPathComponent!
        
        let url = NSURL(string: "http://\(host):\(port)/api/v0/add?stream-cannels=true")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        body.appendData("--\(boundary)\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition : file; name=\"file\"; filename=\"\(fileName)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Transfer-Encoding: binary\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: application/octet-stream\(CRLF)\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(data!)
        body.appendData("\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("--\(boundary)--\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        request.HTTPBody = body
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        
        task.resume()
    }
    
    // add method from SwiftIpfsApi, does not seem to work...
    func add2(filePath:String, completionHandler: ([MerkleNode] -> ())) {
        do {
            try self.ipfs!.add(filePath, completionHandler: completionHandler)
        }
        catch let err as NSError { print("[IPFS.ADD] error: \(err)") }
    }
    
    private func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
}