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
    @IBOutlet weak var userName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "Connexion"
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
    
}
