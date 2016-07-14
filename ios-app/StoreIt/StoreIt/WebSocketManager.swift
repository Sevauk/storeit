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
    
    func closeMoveToolbar() {
        self.navigationManager.moveToolBar?.hidden = true
    }
    
    func updateList() {
        if let list = self.navigationManager.list {
            dispatch_async(dispatch_get_main_queue()) {
                list.reloadData()
            }
        }
    }
    
    func removeRowAtIndex(index: Int) {
        if let list = self.navigationManager.list {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            list.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
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
                                    
                                    for file in files {
                                        let updateElement = UpdateElement(file: file)
                                        
                                        self.navigationManager.updateTree(updateElement)
                                        self.updateList()
                                    }
                                }
                                // FDEL
                                else if (commandType == cmdInfos.FDEL) {
                                	let paths = self.uidFactory.getObjectForUid(uid) as! [String]
                                	
                                    for path in paths {
                                        let updateElement = UpdateElement(path: path)
                                        let index = self.navigationManager.updateTree(updateElement)
                                        
                                        self.removeRowAtIndex(index)
                                    }
                                }
                                
                                // FMOVE
                                else if (commandType == cmdInfos.FMOV) {
                                	let movingOptions = self.uidFactory.getObjectForUid(uid) as! MovingOptions
                                    let updateElementForDeletion = UpdateElement(path: movingOptions.src!)
                                    let updateElementForAddition = UpdateElement(file: movingOptions.file!)
                                    
                                    self.navigationManager.updateTree(updateElementForDeletion)
                                    self.navigationManager.updateTree(updateElementForAddition)
                                    
                                    self.navigationManager.movingOptions = MovingOptions()
                                    
                                    self.closeMoveToolbar()
                                    self.updateList()
                                }

                            }
                        }
                        
                        // ERROR CMD RESPONSE
                        // TODO
                    }
                }
                    
                // Server sent a command (FADD, FUPT, FDEL)
                else if (cmdInfos.SERVER_TO_CLIENT_CMD.contains(command.command)) {
                    if (command.command == "FDEL") {
                        let _: Command? = Mapper<Command<FdelParameters>>().map(request)
                        
                    } else if (command.command == "FMOV") {
                        let _: Command? = Mapper<Command<FmovParameters>>().map(request)
                    } else {
                        let _: Command? = Mapper<Command<DefaultParameters>>().map(request)
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