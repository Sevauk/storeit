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
import GoogleSignIn

class LoginView: UIViewController, FBSDKLoginButtonDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    
    var connectionType: ConnectionType? = nil
    var networkManager: NetworkManager? = nil
    var connectionManager: ConnectionManager? = nil
    var fileManager: FileManager? = nil
    var navigationManager: NavigationManager? = nil
    var ipfsManager: IpfsManager? = nil
    var plistManager: PListManager? = nil

    let port: Int = 7641//8001
    //let host: String = "iglu.mobi"
    //let host: String = "158.69.196.83"
    let host: String = "localhost"
    
    @IBOutlet weak var FBLoginButton: FBSDKLoginButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureFacebook()
        self.configureGoogle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
        
        self.configureFacebook()
        self.configureGoogle()
        
        let lastConnectionType = self.plistManager?.getValueWithKey("connectionType")
        print("[LoginView] Last connexion type : \(lastConnectionType). Trying to auto log if possible...")
        
        if (lastConnectionType == ConnectionType.GOOGLE.rawValue) {
            GIDSignIn.sharedInstance().signInSilently()
            self.initGoogle() // get token refresh it
        } else if (lastConnectionType == ConnectionType.FACEBOOK.rawValue && FBSDKAccessToken.current() != nil) {
            self.initFacebook() // check if fb does a refresh
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let tabBarController = segue.destination as! UITabBarController
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
        let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
        self.present(tabBarController, animated: true, completion: nil)
    }
    
    func logout() {
        print("[LoginView] Logging out...")
        
        if (self.connectionType != nil && self.connectionType! == ConnectionType.FACEBOOK) {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        } else if (self.connectionType != nil && self.connectionType! == ConnectionType.GOOGLE) {
            GIDSignIn.sharedInstance().disconnect()
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
        _ = self.navigationController?.popToRootViewController(animated: true)
        self.logout()
    }
    
    func loginFunction() {
        if let connectionType = self.connectionType?.rawValue {
            
            print("#####")
            GIDAuthentication().refreshTokens{toto in print(toto)}
            print("#####")

            print("FKFKFKFJKJKLF \(GIDSignIn.sharedInstance().currentUser)")

            
            if connectionType == ConnectionType.GOOGLE.rawValue {

                GIDAuthentication().getTokensWithHandler { (token, error) in
                    print("\(token)        \(error)")
                    if let token = token?.accessToken {
                        print("LALALALALALALALAL")
                        self.networkManager?.join(connectionType, accessToken: token, completion: nil)
                    }
                }
            } else {
                if let token = FBSDKAccessToken.current().tokenString {
                    self.networkManager?.join(connectionType, accessToken: token, completion: nil)
                }
            }
        }
    }
    
    @IBAction func logoutSegue(_ segue: UIStoryboardSegue) {
		self.logout()
    }
    
    func initConnection(_ host: String, port: Int, path: String, allItems: [String:File]) {
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
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil) {
        	print(error)
            self.logout()
        }
        else if result.isCancelled {
            print(result)
            self.logout()
        }
        else {
            if result.grantedPermissions.contains("email"){
               self.initFacebook()
            }
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        self.connectionType = ConnectionType.FACEBOOK
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        self.logout()
    }
    
    // MARK: Login with Google
    
    func configureGoogle() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    func sign(_ signIn: GIDSignIn!,
              present viewController: UIViewController!) {
        self.connectionType = ConnectionType.GOOGLE
        self.present(viewController, animated: true, completion: nil)
    }

    func sign(_ signIn: GIDSignIn!,
              dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        initGoogle()
        print(user.authentication.accessToken)
        print("LLKDKDLKJDKLJLJKDKJLDJKLDJKLD   \(GIDAuthentication().accessToken)")
        
        print("AAAAAAA \(GIDSignIn.sharedInstance().currentUser)")

    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        self.logout()
    }
    
    func initGoogle() {
        self.connectionType = ConnectionType.GOOGLE
        self.plistManager?.addValueForKey("connectionType", value: ConnectionType.GOOGLE.rawValue)
        
        self.initConnection(self.host, port: self.port, path: "/Users/gjura_r/Desktop/demo/", allItems: [:])
        self.performSegue(withIdentifier: "StoreItSynchDirSegue", sender: nil)
    }
}




