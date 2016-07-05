//
//  ViewController.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import ObjectMapper
import FBSDKLoginKit

class LoginView: UIViewController, FBSDKLoginButtonDelegate {
    
    var connectionType: ConnectionType? = nil
    var networkManager: NetworkManager? = nil
    var connectionManager: ConnectionManager? = nil
    var fileManager: FileManager? = nil
    var navigationManager: NavigationManager? = nil
    var ipfsManager: IpfsManager? = nil
    var plistManager: PListManager? = nil

    let port: Int = 7641//8001
    let host: String = "localhost"
    
    @IBOutlet weak var FBLoginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureFacebook()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidLoad()
        
        self.configureFacebook()
        
        let lastConnectionType = self.plistManager?.getValueWithKey("connectionType")
        print("[LoginView] Last connexion type : \(lastConnectionType). Trying to auto log if possible...")
        
        if (lastConnectionType == ConnectionType.GOOGLE.rawValue) {
            self.initGoogle()
        } else if (lastConnectionType == ConnectionType.FACEBOOK.rawValue && FBSDKAccessToken.currentAccessToken() != nil) {
            // TODO: check expiration of Facebook token
            self.initFacebook()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabBarController = segue.destinationViewController as! UITabBarController
        let navigationController = tabBarController.viewControllers![0] as! UINavigationController
        let listView = navigationController.viewControllers[0] as! StoreItSynchDirectoryView
        
        listView.navigationItem.title = self.navigationManager?.rootDirTitle

        listView.connectionType = self.connectionType
        listView.networkManager = self.networkManager
        listView.connectionManager = self.connectionManager
        listView.fileManager = self.fileManager
        listView.navigationManager = self.navigationManager
        listView.ipfsManager = self.ipfsManager
    }
    
    func moveToTabBarController() {
        let tabBarController = self.storyboard?.instantiateViewControllerWithIdentifier("tabBarController") as! UITabBarController
        self.presentViewController(tabBarController, animated: true, completion: nil)
    }
    
    func logout() {
        print("[LoginView] Logging out...")
        
        if (self.connectionType != nil && self.connectionType! == ConnectionType.FACEBOOK) {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        } else if (self.connectionType != nil && self.connectionType! == ConnectionType.GOOGLE) {
            self.connectionManager?.forgetTokens()
        }
        
		self.networkManager?.close()
        self.connectionType = nil
        self.networkManager = nil
        self.connectionManager = nil
        self.fileManager = nil
        self.navigationManager = nil
        self.ipfsManager = nil
        
        self.plistManager?.addValueForKey("connectionType", value: ConnectionType.NONE.rawValue)
    }
    
    func logoutToLoginView() {
        self.navigationController?.popToRootViewControllerAnimated(true)
        self.logout()
    }
    
    func loginFunction() {
        let connectionType = self.connectionType?.rawValue
        
        let accessToken: String? = connectionType.map { type in
            if (type == ConnectionType.GOOGLE.rawValue) {
                return (self.connectionManager?.oauth2?.accessToken())!
            } else {
                return FBSDKAccessToken.currentAccessToken().tokenString
            }
        }
        
        self.networkManager?.join(connectionType!, accessToken: accessToken!) { _ in
			//
        }
    }
    
    @IBAction func logoutSegue(segue: UIStoryboardSegue) {
		self.logout()
    }
    
    func initConnection(host: String, port: Int, path: String, allItems: [String:File]) {
        if (self.fileManager == nil) {
            self.fileManager = FileManager(path: path) // Path to local synch dir
        }
        
        if (self.navigationManager == nil) {
            self.navigationManager = NavigationManager(rootDirTitle: "StoreIt", allItems: [:])
        }
        
        if (self.networkManager == nil) {
            self.networkManager = NetworkManager(host: host, port: port, navigationManager: self.navigationManager!)
        }
        
        if (self.ipfsManager == nil) {
            self.ipfsManager = IpfsManager(host: "127.0.0.1", port: 5001)
        }
    	
        self.networkManager?.initConnection(self.loginFunction, logoutFunction: self.logoutToLoginView)
    }
    
    // MARK: Login with Facebook
    
    func configureFacebook() {
        FBLoginButton.readPermissions = ["public_profile", "email"]
        FBLoginButton.delegate = self
    }
    
    func initFacebook() {
        self.connectionType = ConnectionType.FACEBOOK
        self.plistManager?.addValueForKey("connectionType", value: ConnectionType.FACEBOOK.rawValue)
        
        self.initConnection(self.host, port: self.port, path: "/Users/gjura_r/Desktop/demo/", allItems: [:])
        self.performSegueWithIdentifier("StoreItSynchDirSegue", sender: nil)
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if ((error) != nil) {
            self.logout()
        }
        else if result.isCancelled {
            self.logout()
        }
        else {
            if result.grantedPermissions.contains("email"){
               self.initFacebook()
            }
        }
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        self.connectionType = ConnectionType.FACEBOOK
        return true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        self.logout()
    }
    
    // MARK: Login with Google
    
    func initGoogle() {
        if (self.connectionManager == nil) {
            self.connectionType = ConnectionType.GOOGLE
            self.connectionManager = ConnectionManager(connectionType: ConnectionType.GOOGLE)
            self.plistManager?.addValueForKey("connectionType", value: ConnectionType.GOOGLE.rawValue)
        }

        self.connectionManager?.authorize(self)
    }
    
    @IBAction func login(sender: AnyObject) {
    	self.initGoogle()
    }

}

