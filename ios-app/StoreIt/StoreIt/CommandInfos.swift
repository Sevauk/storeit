//
//  CommandInfos.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

struct CommandInfos {
    
    let RESP = "RESP"
    
    let JOIN = "JOIN"
    let FDEL = "FDEL"
    let FADD = "FADD"
    let FUPT = "FUPT"
    let FMOV = "FMOV"
    let FSTR = "FSTR"

    var SERVER_TO_CLIENT_CMD: [String] { return [FADD, FDEL, FUPT, FMOV, FSTR] }
    
    let JOIN_RESPONSE_TEXT = "welcome"
    let SUCCESS_TEXT = "success"
    
    let SUCCESS_CODE = 0
    
    // SERVER ERRORS
    
    let BAD_CREDENTIALS = (1, "Invalid credentials")
    let BAD_SCOPE = (2, "Bad OAuth scope")
    let UNKNOWN_AUTH_TYPE = (3, "Unknown authentication method")
    let SERVER_ERROR = (4, "The server failed")
    let BAD_TREE = (5, "The tree does not match server reprensentation. Login again")
    let BAD_REQUEST = (6, "The request structure is invalid")
    let BAD_PARAMETERS = (7, "The request parameters are invalid")
    let UNKNOWN_REQUEST = (8, "The request is unknown")
    let ENOENT = (9, "No such file or directory")
    let NOT_IMPLEMENTED = (10, "Not implemented")
}