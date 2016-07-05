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
    
    var fileActionSheet: FileActionSheet?
    var data: [UInt8]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(fileOptions))
        self.fileActionSheet = FileActionSheet(title: "Options du fichier", message: nil)
        self.addActionsToFileSheet()
    }
    
    func addActionsToFileSheet() {
        self.fileActionSheet!.addActionToFileActionSheet("Annuler", style: .Cancel, handler: nil)
        self.fileActionSheet!.addActionToFileActionSheet("Enregistrer dans la pellicule", style: .Default, handler: download) // only if photo
        self.fileActionSheet!.addActionToFileActionSheet("Supprimer", style: .Default, handler: deleteFile)
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
        
    }
    
    func fileOptions() {
        self.presentViewController(self.fileActionSheet!.fileActionSheet, animated: true, completion: nil)
    }
}
