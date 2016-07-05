//
//  AlertControllerManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 25/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit

class StoreitActionSheet {
    
    let storeitActionSheet: UIAlertController
    
    init(title: String, message: String?) {
        self.storeitActionSheet = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
    }
    
    func addActionToUploadActionSheet(title: String, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) {
        let newAction: UIAlertAction = UIAlertAction(title: title, style: style, handler: handler)
        self.storeitActionSheet.addAction(newAction)
    }
}