//
//  Extensions.swift
//  StoreIt
//
//  Created by Romain Gjura on 10/11/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit

extension UIViewController {
    func displayAlert(withMessage message: String) {
        let myAlert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        
        myAlert.addAction(okAction)
        
        myAlert.view.tintColor = LIGHT_GREY
        
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer =
            UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
}
