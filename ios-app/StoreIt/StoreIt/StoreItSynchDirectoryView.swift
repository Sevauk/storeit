//
//  StoreItSynchDirectoryView.swift
//  StoreIt
//
//  Created by Romain Gjura on 13/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import Photos
import ObjectMapper
import QuickLook

// TODO: maybe import interface texts from a file for different languages ?

class StoreItSynchDirectoryView:  UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var list: UITableView!
    @IBOutlet weak var moveToolBar: UIToolbar!
    
    // Last opened action sheet (used to determined which cell is selected when tapping button)
    // TODO: maybe find a better way
    var lastSelectedActionSheetForFile: Int?
    
    var actionSheetsManager: ActionSheetsManager?
    
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
        
        self.actionSheetsManager = ActionSheetsManager()
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.UPLOAD, title: "Ajout d'un nouvel élément", message: nil)
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.DIR_OPT, title: "Dossier", message: "Que voulez-vous faire ?")
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.FILE_OPT, title: "Fichier", message: "Que voulez-vous faire ?")
        self.addActionsToActionSheets()
    }
    
    // function triggered when back button of navigation bar is pressed
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if (parent == nil) {
            self.navigationManager?.goPreviousDir()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    	self.moveToolBar.hidden = !(self.navigationManager?.movingOptions.isMoving)!
        
        self.navigationManager?.list = self.list
        self.navigationManager?.moveToolBar = self.moveToolBar
        self.list.reloadData()
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
        
        //let target: File? = sender as? File

        if let target: File = sender as? File {
            if (segue.identifier == "nextDirSegue") {
                
                let listView = (segue.destinationViewController as! StoreItSynchDirectoryView)
                let targetPath = (self.navigationManager?.goToNextDir(target))!
                
                listView.navigationItem.title = targetPath
                
                listView.actionSheetsManager = self.actionSheetsManager
                listView.connectionType = self.connectionType
                listView.networkManager = self.networkManager
                listView.connectionManager = self.connectionManager
                listView.fileManager = self.fileManager
                listView.navigationManager = self.navigationManager
                listView.ipfsManager = self.ipfsManager
                listView.navigationManager?.movingOptions.isMoving = (self.navigationManager?.movingOptions.isMoving)!
            }
            else if (segue.identifier == "showFileSegue") {
                let fileView = segue.destinationViewController as! FileView
                fileView.navigationItem.title = self.navigationManager?.getTargetName(target)
                
                self.ipfsManager?.get(target.IPFSHash) { bytes in
                    //print("[IPFS.GET] received data: \(data)")
                    fileView.bytes = bytes
                    fileView.presentQlPreviewController()
                }
            }
        }
    }

	// MARK: Creation and management of table cells
    
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.navigationManager?.getSortedItems().count)!
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
        let items: [String] = (self.navigationManager?.getSortedItems())!
                
        if (isDir) {
            let cell = self.list.dequeueReusableCellWithIdentifier(CellIdentifiers.Directory.rawValue) as! DirectoryCell
            cell.itemName.text = "\(items[indexPath.row])"
            cell.contextualMenu.tag = indexPath.row
            return cell
        } else {
            let cell = self.list.dequeueReusableCellWithIdentifier(CellIdentifiers.File.rawValue) as! FillCell
            cell.itemName.text = "\(items[indexPath.row])"
            cell.contextualMenu.tag = indexPath.row
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
                    
                    // Maybe begin some loading in interface here...
                    self.ipfsManager?.add(filePath) {
                        (
                        let data, let response, let error) in
                        
                        guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                            print("[IPFS.ADD] Error while IPFS ADD: \(error)")
                            return
                        }

                        // If ipfs add succeed
                        let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        let ipfsAddResponse = Mapper<IpfsAddResponse>().map(dataString)
                        let relativePath = self.navigationManager?.buildPath(filePath.lastPathComponent!)
                        
						let file = self.fileManager?.createFile(relativePath!, metadata: "", IPFSHash: ipfsAddResponse!.hash)
 
                        self.networkManager?.fadd([file!], completion: nil)
                    }
                }
            })
        });
    }
    
    func createNewDirectory(action: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Création de dossier", message: "Entrez le nom du dossier", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler(nil)
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let input = alert.textFields![0] as UITextField

        	// TODO: check input
            
            let relativePath = self.navigationManager?.buildPath(input.text!)
            let newDirectory: File = self.fileManager!.createDir(relativePath!, metadata: "", IPFSHash: "")

            self.networkManager?.fadd([newDirectory], completion: nil)
            
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
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
    
    func moveFile(action: UIAlertAction) -> Void {
        if let index = self.lastSelectedActionSheetForFile {
        	if let selectedFile = self.navigationManager?.getSelectedFileAtRow(NSIndexPath(forRow: index, inSection: 0)) {
                self.moveToolBar.hidden = false
                self.navigationManager?.movingOptions.isMoving = true
                self.navigationManager?.movingOptions.src = selectedFile.path
                self.navigationManager?.movingOptions.file = self.navigationManager?.getFileObjInCurrentDir(selectedFile.path)
            
                self.lastSelectedActionSheetForFile = nil
            }
        }
    }
    
    func deleteFile(action: UIAlertAction) -> Void {
        if let index = self.lastSelectedActionSheetForFile {
            if let selectedFile = navigationManager?.getSelectedFileAtRow(NSIndexPath(forRow: index, inSection: 0)) {
                self.networkManager?.fdel([selectedFile.path], completion: nil)
            }
        }
    }
    
    func renameFile(action: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Renommer l'élément", message: nil, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler(nil)
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let input = alert.textFields![0] as UITextField
            
            // TODO: check input
	
            if let text = input.text {
                if let index = self.lastSelectedActionSheetForFile {
                    if let selectedFile = self.navigationManager?.getSelectedFileAtRow(NSIndexPath(forRow: index, inSection: 0)) {
                        
                        var components = selectedFile.path.componentsSeparatedByString("/").dropFirst()
                        components = components.dropLast()
                        components.append(text)
                        
                        let newPath = "/" + components.joinWithSeparator("/")
                        self.navigationManager?.movingOptions.src = selectedFile.path
                        self.navigationManager?.movingOptions.dest = newPath
                        
                        self.networkManager?.fmove((self.navigationManager?.movingOptions)!, completion: nil)
                        
                        self.lastSelectedActionSheetForFile = nil
                    }
                }
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func addActionsToActionSheets() {
        if let ASManager = self.actionSheetsManager {

            // Main Action Sheet (Upload)
            let uploadAS = ActionSheets.UPLOAD
            var uploadActions: [String:((UIAlertAction) -> Void)?] = [:]
            
            uploadActions["Créer un dossier"] = createNewDirectory
            uploadActions["Importer depuis mes photos et vidéos"] = pickImageFromLibrary
            uploadActions["Prendre avec l'appareil photo"] = takeImageWithCamera
            
            // Dir actions Action Sheet
            let dirAS = ActionSheets.DIR_OPT
            var fileActions: [String:((UIAlertAction) -> Void)?] = [:]
            
            fileActions["Renommer"] = renameFile
            fileActions["Déplacer"] = moveFile
            fileActions["Supprimer"] = deleteFile
            
            // File actions Action Sheet
            let fileAS = ActionSheets.FILE_OPT
            
            fileActions["Télécharger dans la pellicule"] = nil
            
            ASManager.addActionsToActionSheet(uploadAS, actions: uploadActions, cancelHandler: nil)
            ASManager.addActionsToActionSheet(dirAS, actions: fileActions) { _ in
                self.lastSelectedActionSheetForFile = nil
            }
            ASManager.addActionsToActionSheet(fileAS, actions: fileActions) { _ in
                self.lastSelectedActionSheetForFile = nil
            }
        }
    }
    
    func uploadOptions() {
        if let actionSheet = self.actionSheetsManager?.getActionSheet(ActionSheets.UPLOAD) {
            self.presentViewController(actionSheet, animated: true, completion: nil)

        }
    }
    
    func openContextualMenu() {
        if let index = self.lastSelectedActionSheetForFile {
            if let isDir = self.navigationManager?.isSelectedFileAtRowADir(NSIndexPath(forRow: index, inSection: 0)) {
                let actionSheetType: ActionSheets = isDir ? ActionSheets.DIR_OPT : ActionSheets.FILE_OPT
                
                if let actionSheet = self.actionSheetsManager?.getActionSheet(actionSheetType) {
                    self.presentViewController(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func openContextualMenu(sender: AnyObject) {
        self.lastSelectedActionSheetForFile = sender.tag
        self.openContextualMenu()
    }
    
    
    // MARK: move feature
    
    @IBAction func moveInCurrentDirectory(sender: AnyObject) {
        if let src = navigationManager?.movingOptions.src {
            let targetPath = navigationManager?.buildCurrentDirectoryPath()
			let fileName = src.componentsSeparatedByString("/").last!
            let dest = "\(targetPath!)\(targetPath?.characters.last! == "/" ? "" : "/" )\(fileName)"
            
            self.navigationManager?.movingOptions.file?.path = dest
            self.navigationManager?.movingOptions.dest = dest
            
            self.networkManager?.fmove((self.navigationManager?.movingOptions)!, completion: nil)
        }
        
    }
    
    @IBAction func cancelMove(sender: AnyObject) {
        self.moveToolBar.hidden = true
        self.navigationManager?.movingOptions = MovingOptions()
    }
}