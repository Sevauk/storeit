//
//  SuccessResponse.swift
//  StoreIt
//
//  Created by Romain Gjura on 18/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class SuccessResponse : Response {
    
    init(commandUid: Int) {
        let cmdInfos = CommandInfos()
        super.init(code: cmdInfos.SUCCESS_CODE, text: cmdInfos.SUCCESS_TEXT, commandUid: commandUid, command: cmdInfos.RESP, parameters: nil)
    }
    
    required init?(_ map: Map) {
		super.init(map)
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
    }
}