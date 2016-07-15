//
//  ContextualMenuActionSheet.swift
//  StoreIt
//
//  Created by Romain Gjura on 14/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

import Foundation

class ContextualMenuActionSheet {
    
    let contextualMenuActionSheet: UIAlertController
    
    init(title: String, message: String?) {
        self.contextualMenuActionSheet = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
    }
    
    func addActionToFileActionSheet(title: String, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) {
        let newAction: UIAlertAction = UIAlertAction(title: title, style: style, handler: handler)
        self.contextualMenuActionSheet.addAction(newAction)
    }
}