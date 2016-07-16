//
//  FileView.swift
//  StoreIt
//
//  Created by Romain Gjura on 29/06/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import Photos

class FileView: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var data: [UInt8]?

    var actionSheetsManager: ActionSheetsManager? = nil
    var networkManager: NetworkManager? = nil
    var file: File? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(fileOptions))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_settings_white"), style: .Plain, target: self, action: #selector(fileOptions))
        
        print(actionSheetsManager)
        
        if let ASManager = self.actionSheetsManager {
            print("ici")
            if (ASManager.containsActionSheet(ActionSheets.FILE_VIEW_OPT) == false) {
                print("la")
                ASManager.addNewActionSheet(ActionSheets.FILE_VIEW_OPT, title: "Fichier", message: "Que voulez-vous faire ?")
                self.addActionsToActionSheet()
            }
        }
    }
    
    func addActionsToActionSheet() {
        let fileViewAS = ActionSheets.FILE_VIEW_OPT
        var fileViewActions: [String:((UIAlertAction) -> Void)?] = [:]
        
        fileViewActions["Télécharger dans la pellicule"] = download
        fileViewActions["Supprimer"] = deleteFile
        
        self.actionSheetsManager?.addActionsToActionSheet(fileViewAS, actions: fileViewActions, cancelHandler: nil)
    }
    
    func fileDidDownload(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            let alert = UIAlertController(title: "Terminé", message: "Le fichier a été telechargé dans la pellicule", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Erreur", message: error?.localizedDescription, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func download(action: UIAlertAction) -> Void  {
        UIImageWriteToSavedPhotosAlbum(UIImage(data: NSData(bytes: data!))!, self, #selector(fileDidDownload), nil)
    }
    
    func deleteFile(action: UIAlertAction) -> Void  {
        if let file = self.file {
            self.networkManager?.fdel([file.path]) {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    func fileOptions() {
        if let actionSheet = self.actionSheetsManager?.getActionSheet(ActionSheets.FILE_VIEW_OPT) {
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
}
