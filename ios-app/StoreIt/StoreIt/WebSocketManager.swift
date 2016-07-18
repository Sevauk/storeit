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
    
    let url: NSURL
    let ws: WebSocket
    let navigationManager: NavigationManager
    
    var uidFactory: UidFactory
    
    init(host: String, port: Int, uidFactory: UidFactory, navigationManager: NavigationManager) {
        self.url = NSURL(string: "ws://\(host):\(port)/")!
        self.ws = WebSocket(url: url)
        self.navigationManager = navigationManager
        self.uidFactory = uidFactory
    }
    
    private func closeMoveToolbar() {
        self.navigationManager.moveToolBar?.hidden = true
    }
    
    private func updateList() {
        if let list = self.navigationManager.list {
            dispatch_async(dispatch_get_main_queue()) {
                list.reloadData()
            }
        }
    }
    
    private func removeRowAtIndex(index: Int) {
        if let list = self.navigationManager.list {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            list.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    private func deletePaths(paths: [String]) {
        for path in paths {
            let updateElement = UpdateElement(path: path)
            let index = self.navigationManager.updateTree(updateElement)
            
            self.removeRowAtIndex(index)
        }
    }
    
    private func isRenaming(src: String, dest: String) -> Bool {
        // Drop file name to compare path (if the path is the same, it's only a rename)
        let srcComponents = src.componentsSeparatedByString("/").dropLast()
        let destComponents = src.componentsSeparatedByString("/").dropLast()

        if (srcComponents == destComponents) {
            return true
        }
        
        return false
    }
    
    private func renameFile(src: String, dest: String) {
        let updateElementForRename = UpdateElement(src: src, dest: dest)

        self.navigationManager.updateTree(updateElementForRename)
        self.updateList()
    }
    
    private func moveFile(src: String, file: File) {
        let updateElementForDeletion = UpdateElement(path: src)
        let updateElementForAddition = UpdateElement(file: file)
        
        self.navigationManager.updateTree(updateElementForDeletion)
        self.navigationManager.updateTree(updateElementForAddition)
        
        self.navigationManager.movingOptions = MovingOptions()
        
        self.closeMoveToolbar()
        self.updateList()
    }

    private func addFiles(files: [File]) {
        for file in files {
            let updateElement = UpdateElement(file: file)
            
            self.navigationManager.updateTree(updateElement)
            self.updateList()
        }
    }
    
    private func updateFiles(files: [File]) {
        for file in files {
            if (file.IPFSHash != "") {
                let updateElement = UpdateElement(property: Property.IPFSHash, file: file)
                self.navigationManager.updateTree(updateElement)
            }
            if (file.metadata != "") {
                let updateElement = UpdateElement(property: Property.Metadata, file: file)
                self.navigationManager.updateTree(updateElement)
            }
        }
    }
    
    func eventsInitializer(loginFunction: () -> Void, logoutFunction: () -> Void) {
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
            
            if let command: ResponseResolver = Mapper<ResponseResolver>().map(request) {
                if (command.command == cmdInfos.RESP) {
                    
                    // SEREVR HAS RESPONDED
                    if let response: Response = Mapper<Response>().map(request) {
                        
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

                            if (self.uidFactory.isWaitingForReponse(uid)) {
                                
                                let commandType = self.uidFactory.getCommandNameForUid(uid)

                                // FADD
                                if (commandType == cmdInfos.FADD) {
                                    let files = self.uidFactory.getObjectForUid(uid) as! [File]
                                    
                                	self.addFiles(files)
                                }
                                // FDEL
                                else if (commandType == cmdInfos.FDEL) {
                                	let paths = self.uidFactory.getObjectForUid(uid) as! [String]
                                    
                                	self.deletePaths(paths)
                                }
                                
                                // FMOVE
                                else if (commandType == cmdInfos.FMOV) {
                                	let movingOptions = self.uidFactory.getObjectForUid(uid) as! MovingOptions

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
                        let fdelCmd: Command? = Mapper<Command<FdelParameters>>().map(request)
                        
                        if let cmd = fdelCmd {
                            if let paths = cmd.parameters?.files {
                                self.deletePaths(paths)
                            }
                        }
                    }
                    
                    // FMOV
                    else if (command.command == cmdInfos.FMOV) {
                        let fmovCmd: Command? = Mapper<Command<FmovParameters>>().map(request)
                        
                        if let cmd = fmovCmd {
                            if let parameters = cmd.parameters {
                                if (self.isRenaming(parameters.src, dest: parameters.dest)) {
                                    self.renameFile(parameters.src, dest: parameters.dest)
                                } else {
                                    if let file = self.navigationManager.getFileObjByPath(parameters.src) {
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
                        let defaultCmd: Command? = Mapper<Command<DefaultParameters>>().map(request)
                        
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
                        response = ErrorResponse(code: cmdInfos.NOT_IMPLEMENTED.0, text: cmdInfos.NOT_IMPLEMENTED.1, commandUid: command.commandUid)
                    } else {
                        response = SuccessResponse(commandUid: command.commandUid)
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
        
        self.ws.onData = { (data: NSData) in
            print("[Client.WebSocketManager] Client recieved some data: \(data.length)")
        }
        
        self.ws.connect()
    }
    
    func sendRequest(request: String, completion: (() -> ())?) {
        if (self.ws.isConnected) {
            print("[WSManager] request is sending... : \(request)")
            self.ws.writeString(request, completion: completion)
        } else {
            print("[Client.WebSocketManager] Client can't send request \(request) to \(url), WS is disconnected")
        }
    }

}