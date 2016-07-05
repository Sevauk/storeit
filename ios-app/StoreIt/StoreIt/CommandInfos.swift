//
//  CommandInfos.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

typealias uid = Int
typealias name = String
typealias CommandType = (uid, name)

struct CommandInfos {
    let SERVER_TO_CLIENT_CMD = ["FADD", "FDEL", "FUPT", "FMOV"]
    let JOIN: CommandType = (263, "JOIN")
    let FDEL: CommandType = (765, "FDEL")
    let FADD: CommandType = (766, "FADD")
    let FUPT: CommandType = (767, "FUPT")
    let FMOVE: CommandType = (768, "FMOVE")
}