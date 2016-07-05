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
    
    init(host: String, port: Int, navigationManager: NavigationManager) {
        self.url = NSURL(string: "ws://\(host):\(port)/")!
        self.ws = WebSocket(url: url)
        self.navigationManager = navigationManager
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

            let command: ResponseResolver? = Mapper<ResponseResolver>().map(request)
            
            // Server has responded
            if (command?.command == "RESP") {
                let response: Response? = Mapper<Response>().map(request)
               
                // TODO: structure with different response texts
                if (response?.text == "welcome") {
                    let home: File? = response?.parameters!["home"]
                    self.navigationManager.setItems((home?.files)!)
                    self.updateListView()
                }
            }
            
            // Server sent a command (FADD, FUPT, FDEL)
            else if (command != nil && CommandInfos().SERVER_TO_CLIENT_CMD.contains(command!.command)) {
                if (command!.command == "FDEL") {
                	let _: Command? = Mapper<Command<FdelParameters>>().map(request)

                } else if (command!.command == "FMOV") {
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
        
        self.ws.onData = { (data: NSData) in
            print("[Client.WebSocketManager] Client recieved some data: \(data.length)")
        }
        
        self.ws.connect()
    }
    
    func updateListView() {
        // TODO: find a maybe better way to get StoreItSynchDirectoryView
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let mainNavigationController = appDelegate.window?.rootViewController as! UINavigationController
        let tabBarController = mainNavigationController.viewControllers[1] as! UITabBarController
        let navigationController = tabBarController.viewControllers![0] as! UINavigationController
        let listView = navigationController.viewControllers[0] as! StoreItSynchDirectoryView

        dispatch_async(dispatch_get_main_queue()) {
            listView.list!.reloadData()
        }
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