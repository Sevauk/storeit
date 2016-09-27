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
    private let navigationManager = NavigationManager.sharedInstance

    init(host: String, port: Int) {
        self.url = URL(string: "ws://\(host):\(port)/")!
        self.ws = WebSocket(url: url)
    }
    
    func disconnect() {
        ws.disconnect()
    }
    
    func isConnected() -> Bool {
        return ws.isConnected
    }
    
    private func closeMoveToolbar() {
        self.navigationManager.moveToolBar?.isHidden = true
    }
    
    private func updateList() {
        if let list = self.navigationManager.list {
            DispatchQueue.main.async {
                list.reloadData()
            }
        }
    }
    
    private func removeRowAtIndex(_ index: Int) {
        if let list = self.navigationManager.list {
            let indexPath = IndexPath(row: index, section: 0)
            list.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
			list.reloadData()
        }
    }
    
    private func deletePaths(_ paths: [String]) {
        for path in paths {
            let updateElement = UpdateElement(path: path)
                        
            let index = self.navigationManager.updateTree(updateElement)
            
            if (index != -1) {
                self.removeRowAtIndex(index)
            }
        }
    }
    
    private func isRenaming(_ src: String, dest: String) -> Bool {
        // Drop file name to compare path (if the path is the same, it's only a rename)
        let srcComponents = src.components(separatedBy: "/").dropLast()
        let destComponents = dest.components(separatedBy: "/").dropLast()

        if (srcComponents == destComponents) {
            return true
        }
        
        return false
    }
    
    private func renameFile(_ src: String, dest: String) {
        let updateElementForRename = UpdateElement(src: src, dest: dest)

        let index = self.navigationManager.updateTree(updateElementForRename)
        
        if (index != -1) {
            self.updateList()
        }
    }
    
    private func moveFile(_ src: String, file: File) {
        let updateElementForDeletion = UpdateElement(path: src)
        let updateElementForAddition = UpdateElement(file: file, isMoving: true)
        
        let index = self.navigationManager.updateTree(updateElementForDeletion)
        let index_2 = self.navigationManager.updateTree(updateElementForAddition)
        
        self.navigationManager.movingOptions = MovingOptions()
        
        self.closeMoveToolbar()
        
        if (index != -1 || index_2 != -1) {
            self.updateList()
        }
    }

    private func addFiles(_ files: [File]) {
        for file in files {
            let updateElement = UpdateElement(file: file, isMoving: false)

            let index = self.navigationManager.updateTree(updateElement)
            
            if (index != -1) {
                self.updateList()
            }
        }
    }
    
    private func updateFiles(_ files: [File]) {
        for file in files {
            if (file.IPFSHash != "") {
                let updateElement = UpdateElement(property: Property.ipfsHash, file: file)
                _ = self.navigationManager.updateTree(updateElement)
            }
            if (file.metadata != "") {
                let updateElement = UpdateElement(property: Property.metadata, file: file)
                _ = self.navigationManager.updateTree(updateElement)
            }
        }
    }
    
    func eventsInitializer(_ loginFunction: @escaping () -> Void, logoutFunction: @escaping () -> Void) {
        self.ws.onConnect = {
        	print("[Client.WebSocketManager] WebSocket is connected to \(self.url)")
            loginFunction()
        }

        self.ws.onDisconnect = { (error: NSError?) in
        	print("[Client.WebSocketManager] Websocket is disconnected from \(self.url) with error: \(error?.localizedDescription)")
            logoutFunction()
        }

        self.ws.onText = { (request: String) in
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
                                    self.navigationManager.setItems(files)
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
                                    
                                	self.addFiles(files)
                                }
                                // FDEL
                                else if (commandType == cmdInfos.FDEL) {
                                	let paths = UidFactory.getObjectForUid(uid) as! [String]
                                    
                                	self.deletePaths(paths)
                                }
                                
                                // FMOVE
                                else if (commandType == cmdInfos.FMOV) {
                                	let movingOptions = UidFactory.getObjectForUid(uid) as! MovingOptions

                                    if (movingOptions.isMoving) {
                                        self.moveFile(movingOptions.src!, file: movingOptions.file!)
                                    } else {
                                    	self.renameFile(movingOptions.src!, dest: movingOptions.dest!)
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
                                self.deletePaths(paths)
                            }
                        }
                    }
                    
                    // FMOV
                    else if (command.command == cmdInfos.FMOV) {
                        let fmovCmd: Command? = Mapper<Command<FmovParameters>>().map(JSONString: request)

                        if let cmd = fmovCmd {
                            if let parameters = cmd.parameters {
                                if (self.isRenaming(parameters.src, dest: parameters.dest)) {
                                    self.renameFile(parameters.src, dest: parameters.dest)
                                } else {
                                    if let file = self.navigationManager.getFileObjByPath(parameters.src) {
                                        file.path = parameters.dest
                                        self.moveFile(parameters.src, file: file)
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
                            	self.addFiles(files)
                            } else if (command.command == cmdInfos.FUPT) {
                                self.updateFiles(files)
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
                            self.sendRequest(response, completion: nil)
                        }
                    }
                }
                    
                // We don't know what the server wants
                else {
                    print("[Client.Client.WebSocketManager] Request cannot be processed")
                }
            }
            
        }
        
        self.ws.onData = { (data: Data) in
            print("[Client.WebSocketManager] Client recieved some data: \(data.count)")
        }
        
        self.ws.connect()
    }
    
    func sendRequest(_ request: String, completion: (() -> ())?) {
        if (self.ws.isConnected) {
            print("[WSManager] request is sending... : \(request)")
            self.ws.write(string: request, completion: completion)
        } else {
            print("[Client.WebSocketManager] Client can't send request \(request) to \(url), WS is disconnected")
        }
    }

}
