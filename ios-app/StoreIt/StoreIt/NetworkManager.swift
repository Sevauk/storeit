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
    
    //private let _host = "localhost"
    //private let _host = "iglu.mobi"
    //private let _host = "192.168.1.12"
    //private let _host = "localhost"
    private let _host = "louismondesir.me"
    
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
    
    func initConnection(loginHandler: ((Bool, String, Bool) -> ())?, displayer: ((String) -> ())?) {
        WSManager.eventsInitializer(loginHandler: loginHandler, displayer: displayer)
    }
    
    /*func subs(email: String, password: String, isLogging: Bool, completion: ((Bool) -> ())?) {
        let parameters = SubsParameters(email: email, password: password)
        let subsCommand = Command(uid: UidFactory.uid, command: isLogging ? CommandInfos.AUTH : CommandInfos.SUBS, parameters: parameters)
        
        UidFactory.addNewWaitingCommand(CommandInfos.SUBS, objects: (email: email, password: password) as AnyObject)
        
        WSManager.send(command: subsCommand, completion: completion)
    }*/
    
    func joinDeveloper(completion: ((Bool) -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: "dev", accessToken: "developer")
        let joinCommand = Command(uid: UidFactory.uid, command: CommandInfos.JOIN, parameters: parameters)
        
        UidFactory.uid += 1
        
        WSManager.send(command: joinCommand, completion: completion)
    }
    
    func join(authType: String, accessToken: String, completion: ((Bool) -> ())?) {
        let parameters: JoinParameters = JoinParameters(authType: authType, accessToken: accessToken)
        let joinCommand = Command(uid: UidFactory.uid, command: CommandInfos.JOIN, parameters: parameters)
        
        UidFactory.uid += 1

        WSManager.send(command: joinCommand, completion: completion)
    }
    
    func fadd(files: [File], completion: ((Bool) -> ())?) {
        let parameters = DefaultParameters(files: files)
        let faddCommand = Command(uid: UidFactory.uid, command: CommandInfos.FADD, parameters: parameters)

        UidFactory.addNewWaitingCommand(CommandInfos.FADD, objects: files as AnyObject)

        WSManager.send(command: faddCommand, completion: completion)
    }

    func fdel(files: [String], completion: ((Bool) -> ())?) {
      	let parameters = FdelParameters(files: files)
        let fdelCommand = Command(uid: UidFactory.uid, command: CommandInfos.FDEL, parameters: parameters)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FDEL, objects: files as AnyObject)
        
        WSManager.send(command: fdelCommand, completion: completion)
    }
    
    func fupt(files: [File], completion: ((Bool) -> ())?) {
   		let parameters = DefaultParameters(files: files)
        let fuptCommand = Command(uid: UidFactory.uid, command: CommandInfos.FDEL, parameters: parameters)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FUPT, objects: files as AnyObject)
        
        WSManager.send(command: fuptCommand, completion: completion)
    }
    
    func fmove(movingOptions: MovingOptions, completion: ((Bool) -> ())?) {
        let parameters = FmovParameters(src: movingOptions.src!, dest: movingOptions.dest!)
        let fmovCommand = Command(uid: UidFactory.uid, command: CommandInfos.FMOV, parameters: parameters)
        
        UidFactory.addNewWaitingCommand(CommandInfos.FMOV, objects: movingOptions as AnyObject)
        
        WSManager.send(command: fmovCommand, completion: completion)
    }
    
    func rfsh(completion: ((Bool) -> ())?) {
        let rfshCommand = Command<DefaultParameters>(uid: UidFactory.uid, command: CommandInfos.RFSH, parameters: nil)
        
        UidFactory.addNewWaitingCommand(CommandInfos.RFSH, objects: nil)
        
        WSManager.send(command: rfshCommand, completion: nil)
    }
    
}
