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
    
    let cmdInfos = CommandInfos()
    var uidFactory: UidFactory
    
    private let WSManager: WebSocketManager
    
    init(host: String, port: Int, navigationManager: NavigationManager) {
        self.host = host
        self.port = port
        self.uidFactory = UidFactory()
        self.WSManager = WebSocketManager(host: host, port: port, uidFactory: uidFactory, navigationManager: navigationManager)
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
        //let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: accessToken)
        let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: "developer")
        let joinCommand = Command(uid: self.uidFactory.uid, command: cmdInfos.JOIN, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)
        
        self.uidFactory.uid += 1

        self.WSManager.sendRequest(jsonJoinCommand!, completion: completion)
    }
    
    func fadd(files: [File], completion: (() -> ())?) {
        let parameters = DefaultParameters(files: files)
        let faddCommand = Command(uid: self.uidFactory.uid, command: cmdInfos.FADD, parameters: parameters)
        let jsonFaddCommand = Mapper().toJSONString(faddCommand)

        self.uidFactory.addNewWaitingCommand(cmdInfos.FADD, objects: files)

        self.WSManager.sendRequest(jsonFaddCommand!, completion: completion)
    }

    func fdel(files: [String], completion: (() -> ())?) {
      	let parameters = FdelParameters(files: files)
        let fdelCommand = Command(uid: self.uidFactory.uid, command: cmdInfos.FDEL, parameters: parameters)
        let jsonFdelCommand = Mapper().toJSONString(fdelCommand)
        
        self.uidFactory.addNewWaitingCommand(cmdInfos.FDEL, objects: files)
        
        self.WSManager.sendRequest(jsonFdelCommand!, completion: completion)
    }
    
    func fupt(files: [File], completion: (() -> ())?) {
   		let parameters = DefaultParameters(files: files)
        let fuptCommand = Command(uid: self.uidFactory.uid, command: cmdInfos.FDEL, parameters: parameters)
        let jsonFuptCommand = Mapper().toJSONString(fuptCommand)
        
        self.uidFactory.addNewWaitingCommand(cmdInfos.FUPT, objects: files)
        
        self.WSManager.sendRequest(jsonFuptCommand!, completion: completion)
    }
    
    func fmove(movingOptions: MovingOptions, completion: (() -> ())?) {
        let parameters = FmovParameters(src: movingOptions.src!, dest: movingOptions.dest!)
        let fmovCommand = Command(uid: self.uidFactory.uid, command: cmdInfos.FMOV, parameters: parameters)
        let jsonFmovCommand = Mapper().toJSONString(fmovCommand)
        
        self.uidFactory.addNewWaitingCommand(cmdInfos.FMOV, objects: movingOptions)
        
        self.WSManager.sendRequest(jsonFmovCommand!, completion: completion)
    }
    
}