//
//  IpfsManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 24/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import Alamofire

class IpfsManager {
    
    private let host: String
    private let port: Int
    
    init?(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    func get(hash: String, completionHandler: (NSData? -> Void)) {
        print("IPFS GET FILE WITH HASH \(hash) ...")
        Alamofire.request(.GET, "http://ipfs.io/ipfs/\(hash)").responseString { response in
            print("IPFS GET SUCCEEDED...")
        	completionHandler(response.data)
        }
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
        
        if let unwrappedData = data {
            body.appendData(unwrappedData)
        }
        
        body.appendData("\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("--\(boundary)--\(CRLF)".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        request.HTTPBody = body
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        
        task.resume()
    }
    
    private func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
}