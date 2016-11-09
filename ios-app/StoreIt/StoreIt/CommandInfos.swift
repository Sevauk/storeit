//
//  CommandInfos.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

struct CommandInfos {
    
    static let RESP = "RESP"
    
    static let JOIN = "JOIN"
    static let FDEL = "FDEL"
    static let FADD = "FADD"
    static let FUPT = "FUPT"
    static let FMOV = "FMOV"
    static let FSTR = "FSTR"

    static var SERVER_TO_CLIENT_CMD: [String] { return [FADD, FDEL, FUPT, FMOV, FSTR] }
    
    static let JOIN_RESPONSE_TEXT = "welcome"
    static let SUCCESS_TEXT = "success"
    
    static let SUCCESS_CODE = 0
    
    // SERVER ERRORS
    
    static let BAD_CREDENTIALS = (1, "Invalid credentials")
    static let BAD_SCOPE = (2, "Bad OAuth scope")
    static let UNKNOWN_AUTH_TYPE = (3, "Unknown authentication method")
    static let SERVER_ERROR = (4, "The server failed")
    static let BAD_TREE = (5, "The tree does not match server reprensentation. Login again")
    static let BAD_REQUEST = (6, "The request structure is invalid")
    static let BAD_PARAMETERS = (7, "The request parameters are invalid")
    static let UNKNOWN_REQUEST = (8, "The request is unknown")
    static let ENOENT = (9, "No such file or directory")
    static let NOT_IMPLEMENTED = (10, "Not implemented")
    
}
