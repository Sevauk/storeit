//
//  FileActionSheet.swift
//  StoreIt
//
//  Created by Romain Gjura on 29/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

class FileActionSheet {
    
    let fileActionSheet: UIAlertController
    
    init(title: String, message: String?) {
        self.fileActionSheet = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
    }
    
    func addActionToFileActionSheet(title: String, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) {
        let newAction: UIAlertAction = UIAlertAction(title: title, style: style, handler: handler)
        self.fileActionSheet.addAction(newAction)
    }
}