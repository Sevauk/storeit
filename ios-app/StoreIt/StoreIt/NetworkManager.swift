//
//  NetworkManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class NetworkManager {
    
    let host: String
    let port: Int
    
    private let WSManager: WebSocketManager
    
    init(host: String, port: Int, navigationManager: NavigationManager) {
        self.host = host
        self.port = port
        self.WSManager = WebSocketManager(host: host, port: port, navigationManager: navigationManager)
    }
    
    func close() {
        self.WSManager.ws.disconnect()
    }
    
    func isConnected() -> Bool {
        return WSManager.ws.isConnected
    }
    
    func initConnection(loginFunction: () -> Void, logoutFunction: () -> Void) {
        self.WSManager.eventsInitializer(loginFunction, logoutFunction: logoutFunction)
    }
    
    func join(authType: String, accessToken: String, completion: (() -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: accessToken)
        let joinCommand = Command(uid: CommandInfos().JOIN.0, command: CommandInfos().JOIN.1, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)

        self.WSManager.sendRequest(jsonJoinCommand!, completion: completion)
    }
    
    func fadd(files: [File], completion: (() -> ())?) {
        let parameters = DefaultParameters(files: files)
        let faddCommand = Command(uid: CommandInfos().FADD.0, command: CommandInfos().FADD.1, parameters: parameters)
        let jsonFaddCommand = Mapper().toJSONString(faddCommand)

        self.WSManager.sendRequest(jsonFaddCommand!, completion: completion)
    }

    func fdel(files: [String], completion: (() -> ())?) {
      	let parameters = FdelParameters(files: files)
        let fdelCommand = Command(uid: CommandInfos().FDEL.0, command: CommandInfos().FDEL.1, parameters: parameters)
        let jsonFdelCommand = Mapper().toJSONString(fdelCommand)
        
        self.WSManager.sendRequest(jsonFdelCommand!, completion: completion)
    }
    
    func fupt(files: [File], completion: (() -> ())?) {
   		let parameters = DefaultParameters(files: files)
        let fuptCommand = Command(uid: CommandInfos().FDEL.0, command: CommandInfos().FDEL.1, parameters: parameters)
        let jsonFuptCommand = Mapper().toJSONString(fuptCommand)
        
        self.WSManager.sendRequest(jsonFuptCommand!, completion: completion)
    }
    
}