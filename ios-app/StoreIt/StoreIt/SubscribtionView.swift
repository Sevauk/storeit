//
//  SubscribtionView.swift
//  StoreIt
//
//  Created by Romain Gjura on 28/11/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

import UIKit

class SubscribtionView: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordConfirmation: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Inscription"
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func subscribe(_ sender: Any) {
        // TODO : better input checks
        
        guard let email = self.email.text, !self.email.text!.isEmpty else {
            displayAlert(withMessage: "Le champ 'email' ne doit pas être vide.")
            return
        }
        
        guard let password = self.password.text, !self.password.text!.isEmpty  else {
            displayAlert(withMessage: "Le champ 'mot de passe' ne doit pas être vide.")
            return
        }
        
        guard let passwordConfirmation = self.passwordConfirmation.text,
            !self.passwordConfirmation.text!.isEmpty  else {
            displayAlert(withMessage: "Vous devez confirmer votre mot de passe.")
            return
        }
        
        if password != passwordConfirmation {
            displayAlert(withMessage: "Les mots de passe ne doivent pas être différents.")
            return
        }
        
        NetworkManager.shared.subs(email: email, password: password, isLogging: false) { success in
            if (!success) {
                self.displayAlert(withMessage: "L'inscription a échoué. Veuillez réessayer.")
            }
        }
    }

}
