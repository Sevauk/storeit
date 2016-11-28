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
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordConfirmation: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Inscription"
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
    }

}
