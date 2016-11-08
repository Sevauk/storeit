//
//  ParametersView.swift
//  StoreIt
//
//  Created by Romain Gjura on 16/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation


import UIKit

class ParametersView: UIViewController {
    
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var explanations: UILabel!
    @IBOutlet weak var deactivationExplanations: UILabel!
    
    @IBOutlet weak var offlineButton: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarController?.navigationItem.title = "Paramètres"
        tabBarController?.navigationItem.hidesBackButton = true
        
        logoutButton.layer.cornerRadius = 4
    
        explanations.text = "Le mode hors ligne vous permet de consulter des fichiers sans connexion internet"
    	explanations.sizeToFit()
        
        deactivationExplanations.text = "Si vous désactivez ce mode, les fichiers téléchargés seront supprimés."
        deactivationExplanations.sizeToFit()
        
        if let isOfflineActivated = UserDefaults.standard.value(forKey: IS_OFFLINE_ACTIVATED) as? Bool {
        	offlineButton.isOn = isOfflineActivated
        }
        
        offlineButton.addTarget(self, action: #selector(offlineModeActivationState), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    func offlineModeActivationState(offlineSwitch: UISwitch) {
        UserDefaults.standard.set(offlineSwitch.isOn, forKey: IS_OFFLINE_ACTIVATED)
        
        if !offlineSwitch.isOn {
            OfflineManager.shared.clear()
        }
    }
}
