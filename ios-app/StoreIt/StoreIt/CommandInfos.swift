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

    var SERVER_TO_CLIENT_CMD: [String] { return [FADD, FDEL, FUPT, FMOV] }
    
    var JOIN_RESPONSE_TEXT = "welcome"
    var SUCCESS_TEXT = "success"
}