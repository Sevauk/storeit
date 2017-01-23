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
    
    static let host: String = "127.0.0.1"
    static let port: Int = 5001
    
    static func get(hash: String, completionHandler: @escaping ((Data?) -> Void)) {
        Alamofire.request("http://ipfs.io/ipfs/\(hash)").responseString { response in
        	completionHandler(response.data)
        }
    }
    
    // TODO: multipart request with Alamofire
    static func add(fileName: String, data: Data, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let CRLF = "\r\n"
        let boundary = generateBoundaryString()
        
        let url = URL(string: "http://\(host):\(port)/api/v0/add?stream-cannels=true")
        var request = URLRequest(url: url!)
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        body.append("--\(boundary)\(CRLF)".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition : file; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Transfer-Encoding: binary\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: application/octet-stream\(CRLF)\(CRLF)".data(using: String.Encoding.utf8)!)
        
        body.append(data)
        
        body.append("\(CRLF)".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)--\(CRLF)".data(using: String.Encoding.utf8)!)
        
        request.httpBody = body as Data
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        
        task.resume()
    }
    
    private static func generateBoundaryString() -> String
    {
        return "Boundary-\(UUID().uuidString)"
    }
}
