//
//  ActionSheetsManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 16/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

enum ActionSheets {
    case upload
    case dirOpt
    case fileOpt
    case fileViewOpt
}

class ActionSheetsManager {
    
    var actionsSheets: [ActionSheets:UIAlertController]
    
    init() {
        self.actionsSheets = [:]
    }
    
    func addNewActionSheet(_ actionSheetType: ActionSheets, title: String?, message: String?) {
        self.actionsSheets[actionSheetType] = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
    }
    
    func addActionToActionSheet(_ actionSheetType: ActionSheets, title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) {
        let newAction: UIAlertAction = UIAlertAction(title: title, style: style, handler: handler)
        self.actionsSheets[actionSheetType]?.addAction(newAction)
    }
    
    func addActionsToActionSheet(_ actionSheetType: ActionSheets, actions: [String:((UIAlertAction) -> Void)?], cancelHandler: ((UIAlertAction) -> Void)?) {
        for action in actions {
            self.addActionToActionSheet(actionSheetType, title: action.0, style: .default, handler: action.1)
        }
        self.addActionToActionSheet(actionSheetType, title: "Annuler", style: .cancel, handler: cancelHandler)
    }
    
    func getActionSheet(_ actionSheetType: ActionSheets) -> UIAlertController? {
        return self.actionsSheets[actionSheetType]
    }
    
    func containsActionSheet(_ actionSheetType: ActionSheets) -> Bool {
        return actionsSheets.keys.contains(actionSheetType)
    }
}
