//
//  StoreItSynchDirectoryView.swift
//  StoreIt
//
//  Created by Romain Gjura on 13/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import Photos

// TODO: maybe import interface texts from a file for different languages ?

class StoreItSynchDirectoryView: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var list: UITableView!
    
    var alertControllerManager: AlertControllerManager?
    
    var connectionType: ConnectionType? = nil
    var networkManager: NetworkManager? = nil
    var connectionManager: ConnectionManager? = nil
    var fileManager: FileManager? = nil
    var navigationManager: NavigationManager? = nil
    var ipfsManager: IpfsManager? = nil
    
    enum CellIdentifiers: String {
        case Directory = "directoryCell"
        case File = "fileCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.list.delegate = self
        self.list.dataSource = self

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(uploadOptions))

        // if we're at root dir, we can't go back to login view with back navigation controller button
        
        if (self.navigationItem.title == navigationManager!.rootDirTitle) {
            self.navigationItem.hidesBackButton = true
        } else {
            self.navigationItem.hidesBackButton = false
        }
        
        self.alertControllerManager = AlertControllerManager(title: "Importer un fichier", message: nil)
        self.addActionsToActionSheet()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // do some task
            
            while (((self.navigationManager?.items)! == []) == nil) {
   				print("Waiting data to reaload view...")
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.list.reloadData()
            }
        }
    }
    
    // function triggered when back button of navigation bar is pressed
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if (parent == nil) {
            self.navigationManager?.goPreviousDir()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: segues management
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return false // segues are triggered manually
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let target: File? = sender as? File

        if (segue.identifier == "nextDirSegue") {
        
            let listView = (segue.destinationViewController as! StoreItSynchDirectoryView)
            let targetPath = (self.navigationManager?.goToNextDir(target!))!
            
            listView.navigationItem.title = targetPath
            
            listView.connectionType = self.connectionType
            listView.networkManager = self.networkManager
            listView.connectionManager = self.connectionManager
            listView.fileManager = self.fileManager
            listView.navigationManager = self.navigationManager
        }
        else if (segue.identifier == "showFileSegue") {
            let fileView = segue.destinationViewController

            self.ipfsManager?.get((target?.IPFSHash)!) { data in
                print("[IPFS.GET] received data: \(data)")
                // Set file preview on next view here
                // Refresh
            }
            
            fileView.navigationItem.title = self.navigationManager?.getTargetName(target!)
        }
    }

	// MARK: Creation and management of table cells
    
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.navigationManager?.items.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return createItemCellAtIndexPath(indexPath)
    }
    
    // Function triggered when a cell is selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedFile: File = (navigationManager?.getSelectedFileAtRow(indexPath))!
        let isDir: Bool = (self.navigationManager?.isSelectedFileAtRowADir(indexPath))!
        
        if (isDir) {
            self.performSegueWithIdentifier("nextDirSegue", sender: selectedFile)
        } else {
            self.performSegueWithIdentifier("showFileSegue", sender: selectedFile)
        }
    }
    
    func createItemCellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
        
        let isDir: Bool = (self.navigationManager?.isSelectedFileAtRowADir(indexPath))!
        let items: [String] = (self.navigationManager?.items)!
        
        if (isDir) {
            let cell = self.list.dequeueReusableCellWithIdentifier(CellIdentifiers.Directory.rawValue) as! DirectoryCell
            cell.itemName.text = "\(items[indexPath.row])"
            return cell
        } else {
            let cell = self.list.dequeueReusableCellWithIdentifier(CellIdentifiers.File.rawValue) as! FillCell
            cell.itemName.text = "\(items[indexPath.row])"
            return cell
        }
    }
    
    // MARK: Action sheet creation and management
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: {_ in
            let referenceUrl = editingInfo["UIImagePickerControllerReferenceURL"] as! NSURL
            let asset = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil).firstObject as! PHAsset
            
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: PHImageRequestOptions(), resultHandler: {
                (imagedata, dataUTI, orientation, info) in
                if info!.keys.contains(NSString(string: "PHImageFileURLKey"))
                {
                    let filePath = info![NSString(string: "PHImageFileURLKey")] as! NSURL
                    let fileName = filePath.lastPathComponent!
                    
                    print(fileName)
                    
                    // IPFS ADD HERE
                }
            })
        });
    }
    
    func pickImageFromLibrary(action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = true
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }

    func takeImageWithCamera(action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            let camera = UIImagePickerController()
            
            camera.allowsEditing = true
            camera.sourceType = UIImagePickerControllerSourceType.Camera
            camera.delegate = self
            
            self.presentViewController(camera, animated: true, completion: nil)
        }
    }
    
    func addActionsToActionSheet() {
        self.alertControllerManager!.addActionToUploadActionSheet("Annuler", style: .Cancel, handler: nil)
        self.alertControllerManager!.addActionToUploadActionSheet("Depuis mes photos et vidéos", style: .Default, handler: pickImageFromLibrary)
        self.alertControllerManager!.addActionToUploadActionSheet("Depuis l'appareil photo", style: .Default, handler: takeImageWithCamera)
    }
    
    func uploadOptions() {
        self.presentViewController(self.alertControllerManager!.uploadActionSheet, animated: true, completion: nil)
    }
}