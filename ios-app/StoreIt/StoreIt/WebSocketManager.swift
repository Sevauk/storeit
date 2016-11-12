//
//  WebSocketManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 03/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import Starscream
import ObjectMapper

class WebSocketManager {
    
    private let url: URL
    private let ws: WebSocket
    
    private let navigationManager = NavigationManager.shared

    private var loginHandler: ((Bool, String) -> ())?
    
    var manualLogout = false
    
    init(host: String, port: Int) {
        url = URL(string: "ws://\(host):\(port)/")!
        ws = WebSocket(url: url)
    }
    
    func disconnect() {
        ws.disconnect()
    }
    
    func isConnected() -> Bool {
        return ws.isConnected
    }
    
    private func onConnect() {
        print("[Client.WebSocketManager] WebSocket is connected to \(self.url)")
        
        if let token = SessionManager.getToken() {
            if let connectionType = SessionManager.getConnectionType() {
                NetworkManager.shared.join(authType: connectionType.rawValue, accessToken: token) { _ in
                    print("[WebSocketManager] JOIN request succeeded.")
                }
            }
        }

    }
    
    private func onDisconnect(error: NSError?) {
        print("[Client.WebSocketManager] Websocket is disconnected from \(self.url) with error: \(error?.localizedDescription)")
        
        if !self.manualLogout {
            loginHandler?(false, "Une erreur est survenue avec le serveur. Veuillez réessayer plus tard.")
        }
        
        manualLogout = false
    }
    
    private func serverHasResponded(withResponse response: Response) {
		 if (response.code == CommandInfos.SUCCESS_CODE) {
            
            // JOIN RESPONSE
            if (response.text == CommandInfos.JOIN_RESPONSE_TEXT) {
                if let params = response.parameters {
                    let home: File? = params["home"]
                    
                    if let home = home {
                        navigationManager.set(home: home)
                        loginHandler?(true, "Connection succeeded - Home set")
                    }
                }
            }
                
            // CMD RESPONSE
            else if (response.text == CommandInfos.SUCCESS_TEXT) {
                let uid = response.commandUid
                
                if (UidFactory.isWaitingForReponse(uid)) {
                    
                    let commandType = UidFactory.getCommandNameForUid(uid)
                    
                    switch commandType {
                    
                    case CommandInfos.FADD:
                        let files = UidFactory.getObjectForUid(uid) as! [File]
                        
                        navigationManager.add(files: files)
                        
                        break
                        
                    case CommandInfos.FDEL:
                        let paths = UidFactory.getObjectForUid(uid) as! [String]
                        
                        navigationManager.delete(paths: paths)
                        
                        break
                     
                    case CommandInfos.FMOV:
                        let movingOptions = UidFactory.getObjectForUid(uid) as! MovingOptions
                        
                        if (movingOptions.isMoving) {
                            navigationManager.move(file: movingOptions.file!, from: movingOptions.src!)
                        } else {
                            navigationManager.rename(from: movingOptions.src!, to: movingOptions.dest!)
                        }
                        
                        break
                        
                	default:
                            
                        break
                    }
                    
                    // TODO: maybe clean uid then
                }
            }
        }
        
        // ERROR CODE
        else {
        	// TODO: handle error here
        }
    }
    
    private func serverHasSent(aCommand command: String, request: String) {
        
        func _prettyLog<T>(forCommand command: Command<T>) {
            print("<=== [SERVER SENT REQUEST] ===>")
            NSLog(command.toJSONString(prettyPrint: true) ?? "")
        }
        
        func _isRenaming(from src: String, to dest: String) -> Bool {
            // Drop file name to compare path (if the path is the same, it's only a rename)
            let srcComponents = src.components(separatedBy: "/").dropLast()
            let destComponents = dest.components(separatedBy: "/").dropLast()
            
            if (srcComponents == destComponents) {
                return true
            }
            
            return false
        }
        
        switch command {
        
        case CommandInfos.FDEL:
            if let cmd: Command = Mapper<Command<FdelParameters>>().map(JSONString: request) {
                _prettyLog(forCommand: cmd)
                
                if let paths = cmd.parameters?.files {
                    navigationManager.delete(paths: paths)
                }
            }
            
            break
        
        case CommandInfos.FMOV:
            if let cmd: Command = Mapper<Command<FmovParameters>>().map(JSONString: request) {
                _prettyLog(forCommand: cmd)
                
                if let parameters = cmd.parameters {
                    if (_isRenaming(from: parameters.src, to: parameters.dest)) {
                        navigationManager.rename(from: parameters.src, to: parameters.dest)
                    } else {
                        if let file = navigationManager.getFile(at: parameters.src) {
                            file.path = parameters.dest
                            navigationManager.move(file: file, from: parameters.src)
                        }
                    }
                }
            }
            
            break
            
        case CommandInfos.FADD:
            if let cmd: Command = Mapper<Command<DefaultParameters>>().map(JSONString: request) {
                _prettyLog(forCommand: cmd)
                
                if let files = cmd.parameters?.files {
                    navigationManager.add(files: files)
                }
            }
            
            break
            
        case CommandInfos.FUPT:
            if let cmd: Command = Mapper<Command<DefaultParameters>>().map(JSONString: request) {
                _prettyLog(forCommand: cmd)
                
                if let files = cmd.parameters?.files {
                    navigationManager.update(files: files)
                }
            }
            
            break
            
        default:
            break
        
        }
    }
    
    private func respondeToServer(forCommand command: String, uid: Int) {
        // TODO: Respond to server with response depending of the success of the update in the tree

        var response: Response?
        
        if (command == CommandInfos.FSTR) {
            response = ErrorResponse(code: CommandInfos.NOT_IMPLEMENTED.0,
                                     text: CommandInfos.NOT_IMPLEMENTED.1,
                                     commandUid: uid)
        } else {
            response = SuccessResponse(commandUid: uid)
        }
        
        if let response = response {
            let jsonResponse = Mapper().toJSONString(response)
            
            if let jsonResponse = jsonResponse {
                send(request: jsonResponse, completion: nil)
            }
        }
    }
    
    private func onText(request: String) {
        if let command: ResponseResolver = Mapper<ResponseResolver>().map(JSONString: request) {
            
            // SEREVR HAS RESPONDED
            if (command.command == CommandInfos.RESP) {
                if let response: Response = Mapper<Response>().map(JSONString: request) {
                    print("<=== [SERVER RESPONDED] ===>")
                    NSLog(response.toJSONString(prettyPrint: true) ?? "")
                    
                    serverHasResponded(withResponse: response)
                }
            }
                
            // Server has sent a command (FADD, FUPT, FDEL, FUPT)
            else if (CommandInfos.SERVER_TO_CLIENT_CMD.contains(command.command)) {
                serverHasSent(aCommand: command.command, request: request)
                respondeToServer(forCommand: command.command, uid: command.uid)
            }
                
            // We don't know what the server wants
            else {
                print("[Client.Client.WebSocketManager] Request cannot be processed")
            }
        }

    }
 
    private func onData(data: Data) {
        print("[Client.WebSocketManager] Client recieved some data: \(data.count)")
    }
    
    func eventsInitializer(loginHandler: @escaping (Bool, String) -> ()) {
        self.loginHandler = loginHandler
        
        ws.onConnect = onConnect
        ws.onDisconnect = onDisconnect
        ws.onText = onText
        ws.onData = onData
        
        ws.connect()
    }
    
    func send(request: String, completion: (() -> ())?) {
        if (ws.isConnected) {
            print("[WSManager] request is sending... : \(request)")
            ws.write(string: request, completion: completion)
        } else {
            print("[Client.WebSocketManager] Client can't send request \(request) to \(url), WS is disconnected")
        }
    }

}
