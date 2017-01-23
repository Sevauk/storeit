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
        super.init(code: CommandInfos.SUCCESS_CODE,
                   text: CommandInfos.SUCCESS_TEXT,
                   commandUid: commandUid,
                   command: CommandInfos.RESP,
                   parameters: nil)
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
    }
}
