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
    
    static let sharedInstance = NetworkManager()

    private let WSManager: WebSocketManager
    private let _host = "localhost"//"iglu.mobi" // "158.69.196.83"
    private let _port = 7641
    
    var host: String {
    	return _host
    }
    
    var port: Int {
        return _port
    }
    
    let cmdInfos = CommandInfos()
    
    
    private init() {
        self.WSManager = WebSocketManager(host: _host, port: _port)
    }

    func close() {
        self.WSManager.disconnect()
    }
    
    func isConnected() -> Bool {
        return WSManager.isConnected()
    }
    
    func initConnection(loginFunction: @escaping () -> Void, logoutFunction: @escaping () -> Void) {
        self.WSManager.eventsInitializer(loginFunction, logoutFunction: logoutFunction)
    }
    
    func joinDeveloper(completion: (() -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: "dev", accessToken: "developer")
        let joinCommand = Command(uid: UidFactory.uid, command: cmdInfos.JOIN, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)
        
        UidFactory.uid += 1
        
        self.WSManager.sendRequest(jsonJoinCommand!, completion: completion)

    }
    
    func join(_ authType: String, accessToken: String, completion: (() -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: accessToken)
        let joinCommand = Command(uid: UidFactory.uid, command: cmdInfos.JOIN, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)
        
        UidFactory.uid += 1

        self.WSManager.sendRequest(jsonJoinCommand!, completion: completion)
    }
    
    func fadd(_ files: [File], completion: (() -> ())?) {
        let parameters = DefaultParameters(files: files)
        let faddCommand = Command(uid: UidFactory.uid, command: cmdInfos.FADD, parameters: parameters)
        let jsonFaddCommand = Mapper().toJSONString(faddCommand)

        UidFactory.addNewWaitingCommand(cmdInfos.FADD, objects: files as AnyObject)

        self.WSManager.sendRequest(jsonFaddCommand!, completion: completion)
    }

    func fdel(_ files: [String], completion: (() -> ())?) {
      	let parameters = FdelParameters(files: files)
        let fdelCommand = Command(uid: UidFactory.uid, command: cmdInfos.FDEL, parameters: parameters)
        let jsonFdelCommand = Mapper().toJSONString(fdelCommand)
        
        UidFactory.addNewWaitingCommand(cmdInfos.FDEL, objects: files as AnyObject)
        
        self.WSManager.sendRequest(jsonFdelCommand!, completion: completion)
    }
    
    func fupt(_ files: [File], completion: (() -> ())?) {
   		let parameters = DefaultParameters(files: files)
        let fuptCommand = Command(uid: UidFactory.uid, command: cmdInfos.FDEL, parameters: parameters)
        let jsonFuptCommand = Mapper().toJSONString(fuptCommand)
        
        UidFactory.addNewWaitingCommand(cmdInfos.FUPT, objects: files as AnyObject)
        
        self.WSManager.sendRequest(jsonFuptCommand!, completion: completion)
    }
    
    func fmove(_ movingOptions: MovingOptions, completion: (() -> ())?) {
        let parameters = FmovParameters(src: movingOptions.src!, dest: movingOptions.dest!)
        let fmovCommand = Command(uid: UidFactory.uid, command: cmdInfos.FMOV, parameters: parameters)
        let jsonFmovCommand = Mapper().toJSONString(fmovCommand)
        
        UidFactory.addNewWaitingCommand(cmdInfos.FMOV, objects: movingOptions as AnyObject)
        
        self.WSManager.sendRequest(jsonFmovCommand!, completion: completion)
    }
    
}
