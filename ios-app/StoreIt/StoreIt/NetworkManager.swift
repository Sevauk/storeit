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
    
    static let shared = NetworkManager()

    private let WSManager: WebSocketManager
    private let _host = "localhost"//"louismondesir.me"//"localhost"//"iglu.mobi" // "158.69.196.83"
    private let _port = 7641
    
    var host: String {
    	return _host
    }
    
    var port: Int {
        return _port
    }
    
    private init() {
        WSManager = WebSocketManager(host: _host, port: _port)
    }

    func close() {
        WSManager.disconnect()
    }
    
    func isConnected() -> Bool {
        return WSManager.isConnected()
    }
    
    func initConnection(loginHandler: @escaping (Bool, String) -> ()) {
        WSManager.eventsInitializer(loginHandler: loginHandler)
    }
    
    var manualLogout: Bool {
        set {
            WSManager.manualLogout = newValue
        }
        get {
            return WSManager.manualLogout
        }
    }
    
    func joinDeveloper(completion: (() -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: "dev", accessToken: "developer")
        let joinCommand = Command(uid: UidFactory.uid, command: CommandInfos.JOIN, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)
        
        UidFactory.uid += 1
        
        WSManager.send(jsonJoinCommand!, completion: completion)

    }
    
    func join(authType: String, accessToken: String, completion: (() -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: accessToken)
        let joinCommand = Command(uid: UidFactory.uid, command: CommandInfos.JOIN, parameters: parameters)
        let jsonJoinCommand = Mapper().toJSONString(joinCommand)
        
        UidFactory.uid += 1

        WSManager.send(jsonJoinCommand!, completion: completion)
    }
    
    func fadd(files: [File], completion: (() -> ())?) {
        let parameters = DefaultParameters(files: files)
        let faddCommand = Command(uid: UidFactory.uid, command: CommandInfos.FADD, parameters: parameters)
        let jsonFaddCommand = Mapper().toJSONString(faddCommand)

        UidFactory.addNewWaitingCommand(CommandInfos.FADD, objects: files as AnyObject)

        WSManager.send(jsonFaddCommand!, completion: completion)
    }

    func fdel(files: [String], completion: (() -> ())?) {
      	let parameters = FdelParameters(files: files)
        let fdelCommand = Command(uid: UidFactory.uid, command: CommandInfos.FDEL, parameters: parameters)
        let jsonFdelCommand = Mapper().toJSONString(fdelCommand)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FDEL, objects: files as AnyObject)
        
        WSManager.send(jsonFdelCommand!, completion: completion)
    }
    
    func fupt(files: [File], completion: (() -> ())?) {
   		let parameters = DefaultParameters(files: files)
        let fuptCommand = Command(uid: UidFactory.uid, command: CommandInfos.FDEL, parameters: parameters)
        let jsonFuptCommand = Mapper().toJSONString(fuptCommand)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FUPT, objects: files as AnyObject)
        
        WSManager.send(jsonFuptCommand!, completion: completion)
    }
    
    func fmove(movingOptions: MovingOptions, completion: (() -> ())?) {
        let parameters = FmovParameters(src: movingOptions.src!, dest: movingOptions.dest!)
        let fmovCommand = Command(uid: UidFactory.uid, command: CommandInfos.FMOV, parameters: parameters)
        let jsonFmovCommand = Mapper().toJSONString(fmovCommand)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FMOV, objects: movingOptions as AnyObject)
        
        WSManager.send(jsonFmovCommand!, completion: completion)
    }
    
}
