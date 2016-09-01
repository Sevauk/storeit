//
//  ActionSheetsManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 16/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

enum ActionSheets {
    case UPLOAD
    case DIR_OPT
    case FILE_OPT
    case FILE_VIEW_OPT
}

class ActionSheetsManager {
    
    var actionsSheets: [ActionSheets:UIAlertController]
    
    init() {
        self.actionsSheets = [:]
    }
    
    func addNewActionSheet(actionSheetType: ActionSheets, title: String?, message: String?) {
        self.actionsSheets[actionSheetType] = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
    }
    
    func addActionToActionSheet(actionSheetType: ActionSheets, title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) {
        let newAction: UIAlertAction = UIAlertAction(title: title, style: style, handler: handler)
        self.actionsSheets[actionSheetType]?.addAction(newAction)
    }
    
    func addActionsToActionSheet(actionSheetType: ActionSheets, actions: [String:((UIAlertAction) -> Void)?], cancelHandler: ((UIAlertAction) -> Void)?) {
        for action in actions {
            self.addActionToActionSheet(actionSheetType, title: action.0, style: .Default, handler: action.1)
        }
        self.addActionToActionSheet(actionSheetType, title: "Annuler", style: .Cancel, handler: cancelHandler)
    }
    
    func getActionSheet(actionSheetType: ActionSheets) -> UIAlertController? {
        return self.actionsSheets[actionSheetType]
    }
    
    func containsActionSheet(actionSheetType: ActionSheets) -> Bool {
        return actionsSheets.keys.contains(actionSheetType)
    }
}