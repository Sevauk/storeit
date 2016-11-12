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

struct SocketErrors {
    static let closed_by_server = "connection closed by server"
    static let no_internet_connectivity = "The operation couldn’t be completed. Socket is not connected"
    static let connection_impossible = "The operation couldn’t be completed. Connection refused"
}

class WebSocketManager {
    
    private let url: URL
    private var ws: WebSocket?
    
    
    private let navigationManager = NavigationManager.shared

    private var loginHandler: ((Bool, String) -> ())?
    private var displayer: ((String) -> ())?
        
    init(host: String, port: Int) {
        url = URL(string: "ws://\(host):\(port)/")!
    }
    
    func disconnect() {
        ws?.disconnect()
    }
    
    func isConnected() -> Bool {
        return (ws?.isConnected)!
    }
    
    private func prettyLog<T>(forCommand command: Command<T>) {
        NSLog(command.toJSONString(prettyPrint: true) ?? "Cannot pretty print command")
    }
    
    private func prettyLog(forResponse response: Response) {
        NSLog(response.toJSONString(prettyPrint: true) ?? "Cannot pretty print response")
    }
    
    private func onConnect() {
        print("[Client.WebSocketManager] WebSocket is connected to \(self.url)")
        
        if let token = SessionManager.getToken() {
            if let connectionType = SessionManager.getConnectionType() {
                NetworkManager.shared.join(authType: connectionType.rawValue,
                                           accessToken: token,
                                           completion: nil)
            }
        }

    }
    
    private func onDisconnect(error: NSError?) {
        if let error = error?.localizedDescription {
        	print("[Client.WebSocketManager] Websocket is disconnected from \(url) with error: \(error)")
        
            switch error {
            
            case SocketErrors.connection_impossible:
                loginHandler?(false, "Une erreur est survenue avec le serveur. Veuillez réessayer plus tard.")
                break
                
            case SocketErrors.closed_by_server:
                break
                
            case SocketErrors.no_internet_connectivity:
                break
            
            default:
                break
            }
        	
        }
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
        	displayer?(response.text) // TODO: user friendly display
        }
    }
    
    private func serverHasSent(aCommand command: String, request: String) {
        
        func _isRenaming(from src: String, to dest: String) -> Bool {
            // Drop file name to compare path (if the path is the same, it's only a rename)
            let srcComponents = src.components(separatedBy: "/").dropLast()
            let destComponents = dest.components(separatedBy: "/").dropLast()
            
            if (srcComponents == destComponents) {
                return true
            }
            
            return false
        }
    
        print("<=== [SERVER SENT REQUEST] ===>")
        
        switch command {
    
        case CommandInfos.FDEL:
            if let cmd: Command = Mapper<Command<FdelParameters>>().map(JSONString: request) {
                prettyLog(forCommand: cmd)
                
                if let paths = cmd.parameters?.files {
                    navigationManager.delete(paths: paths)
                }
            }
            
            break
        
        case CommandInfos.FMOV:
            if let cmd: Command = Mapper<Command<FmovParameters>>().map(JSONString: request) {
                prettyLog(forCommand: cmd)
                
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
                prettyLog(forCommand: cmd)
                
                if let files = cmd.parameters?.files {
                    navigationManager.add(files: files)
                }
            }
            
            break
            
        case CommandInfos.FUPT:
            if let cmd: Command = Mapper<Command<DefaultParameters>>().map(JSONString: request) {
                prettyLog(forCommand: cmd)
                
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
        	send(response: response, completion: nil)
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
    
    func eventsInitializer(loginHandler: @escaping (Bool, String) -> (), displayer: @escaping (String) -> ()) {
        ws = WebSocket(url: url)
        
        self.loginHandler = loginHandler
        self.displayer = displayer
        
        ws?.onConnect = onConnect
        ws?.onDisconnect = onDisconnect
        ws?.onText = onText
        ws?.onData = onData
        
        ws?.connect()
    }
    
    func send<T>(command: Command<T>, completion: ((Bool) -> ())?) {
        print("<=== [SENDING REQUEST] ===>")
		prettyLog(forCommand: command)
        
        if let ws = ws {
            if (ws.isConnected) {
                if let command = Mapper().toJSONString(command) {
                    ws.write(string: command) { _ in
                        print("<=== [REQUEST SENT] ===>")
                        completion?(true)
                    }
                } else {
                    print("<=== [REQUEST NOT SENT] ===>")
                    completion?(false)
                }
            } else {
                print("<=== [REQUEST NOT SENT] ===>")
                completion?(false)
            }
        } else {
            print("<=== [REQUEST NOT SENT] ===>")
            completion?(false)
        }
    }
    
    func send(response: Response, completion: (() -> ())?) {
        print("<=== [SENDING RESPONSE] ===>")
        prettyLog(forResponse: response)
        
        if let ws = ws {
            if (ws.isConnected) {
                if let response = Mapper().toJSONString(response) {
                    ws.write(string: response) { _ in
                        print("<=== [RESPONSE SENT] ===>")
                    }
                } else {
                    print("<=== [RESPONSE NOT SENT] ===>")
                }
            } else {
                print("<=== [RESPONSE NOT SENT] ===>")
            }
        } else {
            print("<=== [RESPONSE NOT SENT] ===>")
        }
    }
}
