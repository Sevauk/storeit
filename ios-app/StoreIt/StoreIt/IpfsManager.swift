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
    
    fileprivate let host: String
    fileprivate let port: Int
    
    init?(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    func get(_ hash: String, completionHandler: @escaping ((Data?) -> Void)) {
        print("IPFS GET FILE WITH HASH \(hash) ...")
        Alamofire.request(.GET, "http://ipfs.io/ipfs/\(hash)").responseString { response in
            print("IPFS GET SUCCEEDED...")
        	completionHandler(response.data)
        }
    }
    
    func add(_ filePath: URL, completionHandler: (Data?, URLResponse?, NSError?) -> Void) {
        let CRLF = "\r\n"
        let boundary = self.generateBoundaryString()
        
        let data = try? Data(contentsOf: filePath)
        let fileName = filePath.lastPathComponent
        
        let url = URL(string: "http://\(host):\(port)/api/v0/add?stream-cannels=true")
        let request = NSMutableURLRequest(url: url!)
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        body.append("--\(boundary)\(CRLF)".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition : file; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Transfer-Encoding: binary\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: application/octet-stream\(CRLF)\(CRLF)".data(using: String.Encoding.utf8)!)
        
        if let unwrappedData = data {
            body.append(unwrappedData)
        }
        
        body.append("\(CRLF)".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)--\(CRLF)".data(using: String.Encoding.utf8)!)
        
        request.httpBody = body as Data
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        
        task.resume()
    }
    
    fileprivate func generateBoundaryString() -> String
    {
        return "Boundary-\(UUID().uuidString)"
    }
}
