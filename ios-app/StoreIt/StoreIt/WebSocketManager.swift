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
    
    private func closeMoveToolbar() {
        navigationManager.moveToolBar?.isHidden = true
    }
    
    private func updateList() {
        if let list = navigationManager.list {
            DispatchQueue.main.async {
                list.reloadData()
            }
        }
    }
    
    private func removeRow(at index: Int) {
        if let list = navigationManager.list {
            let indexPath = IndexPath(row: index, section: 0)
            list.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
			list.reloadData()
        }
    }
    
    private func delete(paths: [String]) {
        for path in paths {
            let updateElement = UpdateElement(path: path)
                        
            let index = navigationManager.updateTree(with: updateElement)
            
            if (index != -1) {
                removeRow(at: index)
            }
        }
    }
    
    private func isRenaming(from src: String, to dest: String) -> Bool {
        // Drop file name to compare path (if the path is the same, it's only a rename)
        let srcComponents = src.components(separatedBy: "/").dropLast()
        let destComponents = dest.components(separatedBy: "/").dropLast()

        if (srcComponents == destComponents) {
            return true
        }
        
        return false
    }
    
    private func rename(from src: String, to dest: String) {
        let updateElementForRename = UpdateElement(src: src, dest: dest)

        let index = navigationManager.updateTree(with: updateElementForRename)
        
        if (index != -1) {
            updateList()
        }
    }
    
    private func move(file: File, from src: String) {
        let updateElementForDeletion = UpdateElement(path: src)
        let updateElementForAddition = UpdateElement(file: file, isMoving: true)
        
        let index = navigationManager.updateTree(with: updateElementForDeletion)
        let index_2 = navigationManager.updateTree(with: updateElementForAddition)
        
        navigationManager.movingOptions = MovingOptions()
        
        closeMoveToolbar()
        
        if (index != -1 || index_2 != -1) {
            updateList()
        }
    }

    private func add(files: [File]) {
        for file in files {
            let updateElement = UpdateElement(file: file, isMoving: false)

            let index = self.navigationManager.updateTree(with: updateElement)
            
            if (index != -1) {
                updateList()
            }
        }
    }
    
    private func update(files: [File]) {
        for file in files {
            if (file.IPFSHash != "") {
                let updateElement = UpdateElement(property: Property.ipfsHash, file: file)
                _ = navigationManager.updateTree(with: updateElement)
            }
            if (file.metadata != "") {
                let updateElement = UpdateElement(property: Property.metadata, file: file)
                _ = navigationManager.updateTree(with: updateElement)
            }
        }
    }
    
    func eventsInitializer(_ loginFunction: @escaping () -> Void, logoutFunction: @escaping () -> Void) {
        ws.onConnect = {
        	print("[Client.WebSocketManager] WebSocket is connected to \(self.url)")
            loginFunction()
        }

        ws.onDisconnect = { (error: NSError?) in
        	print("[Client.WebSocketManager] Websocket is disconnected from \(self.url) with error: \(error?.localizedDescription)")
            logoutFunction()
        }

        ws.onText = { (request: String) in
            print("[Client.WebSocketManager] Client recieved a request : \(request)")

            let cmdInfos = CommandInfos()
            
            if let command: ResponseResolver = Mapper<ResponseResolver>().map(JSONString: request) {
                if (command.command == cmdInfos.RESP) {
                    
                    // SEREVR HAS RESPONDED
                    if let response: Response = Mapper<Response>().map(JSONString: request) {
                        
                        // JOIN RESPONSE
                        if (response.text == cmdInfos.JOIN_RESPONSE_TEXT) {
                            if let params = response.parameters {
                                let home: File? = params["home"]
                                
                                if let files = home?.files {
                                    self.navigationManager.set(with: files)
                                    self.updateList()
                                }
                            }
                        }
                            
                        // SUCCESS CMD RESPONSE
                        else if (response.text == cmdInfos.SUCCESS_TEXT) {
                            let uid = response.commandUid

                            if (UidFactory.isWaitingForReponse(uid)) {
                                
                                let commandType = UidFactory.getCommandNameForUid(uid)

                                // FADD
                                if (commandType == cmdInfos.FADD) {
                                    let files = UidFactory.getObjectForUid(uid) as! [File]
                                    
                                    self.add(files: files)
                                }
                                // FDEL
                                else if (commandType == cmdInfos.FDEL) {
                                	let paths = UidFactory.getObjectForUid(uid) as! [String]
                                    
                                    self.delete(paths: paths)
                                }
                                
                                // FMOVE
                                else if (commandType == cmdInfos.FMOV) {
                                	let movingOptions = UidFactory.getObjectForUid(uid) as! MovingOptions

                                    if (movingOptions.isMoving) {
                                        self.move(file: movingOptions.file!, from: movingOptions.src!)
                                    } else {
                                        self.rename(from: movingOptions.src!, to: movingOptions.dest!)
                                    }
                                }
                            }
                        }
                        
                        // ERROR CMD RESPONSE
                        // TODO
                    }
                }
                    
                // Server has sent a command (FADD, FUPT, FDEL, FUPT)
                else if (cmdInfos.SERVER_TO_CLIENT_CMD.contains(command.command)) {
                    
                    // FDEL
                    if (command.command == cmdInfos.FDEL) {
                        let fdelCmd: Command? = Mapper<Command<FdelParameters>>().map(JSONString: request)
                        
                        if let cmd = fdelCmd {
                            if let paths = cmd.parameters?.files {
                                self.delete(paths: paths)
                            }
                        }
                    }
                    
                    // FMOV
                    else if (command.command == cmdInfos.FMOV) {
                        let fmovCmd: Command? = Mapper<Command<FmovParameters>>().map(JSONString: request)

                        if let cmd = fmovCmd {
                            if let parameters = cmd.parameters {
                                if (self.isRenaming(from: parameters.src, to: parameters.dest)) {
                                    self.rename(from: parameters.src, to: parameters.dest)
                                } else {
                                    if let file = self.navigationManager.getFile(at: parameters.src) {
                                        file.path = parameters.dest
                                        self.move(file: file, from: parameters.src)
                                    }
                                }
                            }
                        }
                    }
                        
                    else if (command.command == cmdInfos.FSTR) {
                        // TODO
                    }
                    
                    // FADD / FUPT
                    else {
                        let defaultCmd: Command? = Mapper<Command<DefaultParameters>>().map(JSONString: request)
                        
                        if let files = defaultCmd?.parameters?.files {
                            if (command.command == cmdInfos.FADD) {
                                self.add(files: files)
                            } else if (command.command == cmdInfos.FUPT) {
                                self.update(files: files)
                            }
                        }
                    }
                    
                    // TODO: Respond to server with response depending of the success of the update in the tree
                    var response: Response?
                    var jsonResponse: String?
                    
                    if (command.command == cmdInfos.FSTR) {
                        response = ErrorResponse(code: cmdInfos.NOT_IMPLEMENTED.0, text: cmdInfos.NOT_IMPLEMENTED.1, commandUid: command.uid)
                    } else {
                        response = SuccessResponse(commandUid: command.uid)
                    }
                    
                    if let unwrapResp = response {
                        jsonResponse = Mapper().toJSONString(unwrapResp)
                        if let response = jsonResponse {
                            self.send(response, completion: nil)
                        }
                    }
                }
                    
                // We don't know what the server wants
                else {
                    print("[Client.Client.WebSocketManager] Request cannot be processed")
                }
            }
            
        }
        
        ws.onData = { (data: Data) in
            print("[Client.WebSocketManager] Client recieved some data: \(data.count)")
        }
        
        ws.connect()
    }
    
    func send(_ request: String, completion: (() -> ())?) {
        if (ws.isConnected) {
            print("[WSManager] request is sending... : \(request)")
            ws.write(string: request, completion: completion)
        } else {
            print("[Client.WebSocketManager] Client can't send request \(request) to \(url), WS is disconnected")
        }
    }

}
