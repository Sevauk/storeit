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

// TODO: maybe import interface texts from a file for different languages ?

class StoreItSynchDirectoryView:  UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var list: UITableView!
    @IBOutlet weak var moveToolBar: UIToolbar!
    
    // Last opened action sheet (used to determined which cell is selected when tapping button)
    // TODO: maybe find a better way
    var lastSelectedActionSheetForFile: Int?
    
    var contextualMenuActionSheet: ContextualMenuActionSheet?
    var storeitActionSheet: StoreitActionSheet?
    
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
        
        // TODO: Generic class for action sheets !!!
        self.storeitActionSheet = StoreitActionSheet(title: "Choisissez une option", message: nil)
        self.contextualMenuActionSheet = ContextualMenuActionSheet(title: "Choisissez une option", message: nil)

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
            listView.ipfsManager = self.ipfsManager
            listView.navigationManager?.movingOptions.isMoving = (self.navigationManager?.movingOptions.isMoving)!
        }
        else if (segue.identifier == "showFileSegue") {
            let fileView = segue.destinationViewController as! FileView
            fileView.navigationItem.title = self.navigationManager?.getTargetName(target!)

            self.ipfsManager?.get(target!.IPFSHash) { data in
                //print("[IPFS.GET] received data: \(data)")
                fileView.data = data
            }
            
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
            cell.contextualMenu.tag = indexPath.row
            return cell
        } else {
            let cell = self.list.dequeueReusableCellWithIdentifier(CellIdentifiers.File.rawValue) as! FillCell
            cell.itemName.text = "\(items[indexPath.row])"
            cell.contextualMenu.tag = indexPath.row
            return cell
        }
    }

    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let selectedFile = navigationManager?.getSelectedFileAtRow(indexPath) {
                self.networkManager?.fdel([selectedFile.path], completion: nil)
            }
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
        self.storeitActionSheet?.addActionToUploadActionSheet("Annuler", style: .Cancel, handler: nil)
        self.storeitActionSheet?.addActionToUploadActionSheet("Créer un dossier", style: .Default, handler: createNewDirectory)
        self.storeitActionSheet?.addActionToUploadActionSheet("Importer depuis mes photos et vidéos", style: .Default, handler: pickImageFromLibrary)
        self.storeitActionSheet?.addActionToUploadActionSheet("Prendre avec l'appareil photo", style: .Default, handler: takeImageWithCamera)
        
        self.contextualMenuActionSheet?.addActionToFileActionSheet("Annuler", style: .Cancel) { _ in
            self.lastSelectedActionSheetForFile = nil
        }
        self.contextualMenuActionSheet?.addActionToFileActionSheet("Renommer", style: .Default, handler: renameFile)
        self.contextualMenuActionSheet?.addActionToFileActionSheet("Déplacer", style: .Default, handler: moveFile)
        self.contextualMenuActionSheet?.addActionToFileActionSheet("Supprimer", style: .Default, handler: deleteFile)
    }
    
    func uploadOptions() {
        self.presentViewController(self.storeitActionSheet!.storeitActionSheet, animated: true, completion: nil)
    }
    
    func openContextualMenu() {
        self.presentViewController(self.contextualMenuActionSheet!.contextualMenuActionSheet, animated: true, completion: nil)
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