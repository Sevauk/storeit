//
//  StoreItLoginView.swift
//  StoreIt
//
//  Created by Romain Gjura on 28/11/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import UIKit

class StoreItLoginView: UIViewController {
    
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var email: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "Connexion"
        
        hideKeyboardWhenTappedAround()
        
        NetworkManager.shared.initConnection(loginHandler: loginCallback, displayer: displayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func connection(_ sender: Any) {
    
    }
    
    func displayer(message: String) {
        displayAlert(withMessage: message)
    }
    
    func loginCallback(success: Bool, message: String, goToLoginView: Bool) {
        print("[LoginView] logginCallback -> success \(success) with message \(message)")
        
        if success {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.shouldSupportAllOrientations = true
            
            performSegue(withIdentifier: "storeitSubsToSynchDir", sender: nil)
        } else {
            if (goToLoginView) {
                _ = navigationController?.popToRootViewController(animated: true)
            }
            
            OAuthServices.shared.logout()
            displayAlert(withMessage: message)
        }
    }
}
