//
//  ActionSheetsManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 16/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

enum ActionSheet {
    case upload
    case dirOpt
    case fileOpt
    case fileViewOpt
}

class ActionSheetsManager {
    
    private static var actionSheets: [ActionSheet:UIAlertController] = [:]
    
    static func isInitialized() -> Bool {
        return !ActionSheetsManager.actionSheets.isEmpty
    }
    
    static func add(newActionSheetType: ActionSheet, title: String?, message: String?) {
        ActionSheetsManager.actionSheets[newActionSheetType] = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
    }
    
    static func add(newAction: UIAlertAction, to actionSheetType: ActionSheet) {
        ActionSheetsManager.actionSheets[actionSheetType]?.addAction(newAction)
    }
    
    static func buildAction(title: String, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
    
    static func buildDefaultAction(title: String, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return ActionSheetsManager.buildAction(title: title, style: .default, handler: handler)
    }
    
    static func buildCancelAction(handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return ActionSheetsManager.buildAction(title: "Annuler", style: .cancel, handler: handler)
    }
    
    static func getActionSheet(actionSheetType: ActionSheet) -> UIAlertController? {
        return ActionSheetsManager.actionSheets[actionSheetType]
    }
    
    static func containsActionSheet(actionSheetType: ActionSheet) -> Bool {
        return ActionSheetsManager.actionSheets.keys.contains(actionSheetType)
    }
}

