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

enum CellIdentifiers: String {
    case directory = "directoryCell"
    case file = "fileCell"
}

class SynchDirView:  UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var list: UITableView!
    @IBOutlet weak var moveToolBar: UIToolbar!
    
    var selectedIndex: Int? = nil
    
    let networkManager = NetworkManager.sharedInstance
    let navigationManager = NavigationManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        list.delegate = self
        list.dataSource = self

    	navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
    	                                                    target: self,
    	                                                    action: #selector(uploadOptions))
        
        if (!ActionSheetsManager.isInitialized()) {
            addActions()
        }
    }
    
    // function triggered when back button of navigation bar is pressed
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
        if (parent == nil) {
            navigationManager.goPreviousDir()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    	
        moveToolBar.isHidden = !navigationManager.movingOptions.isMoving
        
        navigationManager.list = list
        navigationManager.moveToolBar = moveToolBar

        let currentPath = navigationManager.buildCurrentDirectoryPath()
        
        navigationItem.title = ( currentPath == "/" ?
            navigationManager.rootDirTitle : currentPath.components(separatedBy: "/").last!)
        
        list.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: segues management
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false // segues are triggered manually
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target: File = sender as? File {
            if (segue.identifier == "nextDirSegue") {
                
                let listView = (segue.destination as! SynchDirView)
                _ = navigationManager.goToNextDir(target)
                
                listView.navigationManager.movingOptions.isMoving = navigationManager.movingOptions.isMoving
            }
            else if (segue.identifier == "showFileSegue") {
                let fileView = segue.destination as! FileView
                
                fileView.navigationItem.title = navigationManager.getTargetName(target)
                fileView.showActivityIndicatory()

                IpfsManager.get(hash: target.IPFSHash) { data in
                    fileView.data = data
                    fileView.presentQlPreviewController()
                }
            }
        }
    }

	// MARK: Creation and management of table cells
    
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return navigationManager.getSortedItems().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createItemCellAtIndexPath(indexPath: indexPath)
    }
    
    // Function triggered when a cell is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedFile: File = navigationManager.getSelectedFileAtRow(indexPath: indexPath) {
            let isDir: Bool = navigationManager.isSelectedFileAtRowADir(indexPath: indexPath)
            
            if (isDir) {
                self.performSegue(withIdentifier: "nextDirSegue", sender: selectedFile)
            } else {
                self.performSegue(withIdentifier: "showFileSegue", sender: selectedFile)
            }
        }
    }
    
    func createItemCellAtIndexPath(indexPath: IndexPath) -> UITableViewCell {
        let isDir: Bool = navigationManager.isSelectedFileAtRowADir(indexPath: indexPath)
        let items: [String] = navigationManager.getSortedItems()
                
        if (isDir) {
            let cell = list.dequeueReusableCell(withIdentifier: CellIdentifiers.directory.rawValue) as! DirectoryCell
            cell.itemName.text = "\(items[(indexPath as NSIndexPath).row])"
            cell.contextualMenu.tag = (indexPath as NSIndexPath).row
            return cell
        } else {
            let cell = list.dequeueReusableCell(withIdentifier: CellIdentifiers.file.rawValue) as! FillCell
            cell.itemName.text = "\(items[(indexPath as NSIndexPath).row])"
            cell.contextualMenu.tag = (indexPath as NSIndexPath).row
            return cell
        }
    }

    // MARK: Action sheet creation and management
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        dismiss(animated: true, completion: {_ in
            let referenceUrl = editingInfo["UIImagePickerControllerReferenceURL"] as! URL
            
            if let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil).firstObject {
                PHImageManager.default().requestImageData(for: asset, options: PHImageRequestOptions(), resultHandler: {
                    (imagedata, dataUTI, orientation, info) in
                    
                    if info!.keys.contains(NSString(string: "PHImageFileURLKey"))
                    {
                        let filePath = info![NSString(string: "PHImageFileURLKey")] as! URL
                        
                        // Maybe begin some loading in interface here...
                        IpfsManager.add(filePath: filePath) {
                            (
                            data, response, error) in
                            
                            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                                print("[IPFS.ADD] Error while IPFS ADD: \(error)")
                                return
                            }
                            
                            // If ipfs add succeed
                            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                            let ipfsAddResponse = Mapper<IpfsAddResponse>().map(JSONString: dataString as String)
                            let relativePath = self.navigationManager.buildPath(filePath.lastPathComponent)
                            
                            let file = self.navigationManager.createFile(relativePath, metadata: "", IPFSHash: ipfsAddResponse!.hash)
                            
                            self.networkManager.fadd([file], completion: nil)
                        }
                    }
                })
            }
        });
    }
    
    func createNewDirectory(action: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Création de dossier", message: "Entrez le nom du dossier", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            let input = alert.textFields![0] as UITextField

        	// TODO: check input
            
            let relativePath = self.navigationManager.buildPath(input.text!)
            let newDirectory: File = self.navigationManager.createDir(relativePath, metadata: "", IPFSHash: "")

            self.networkManager.fadd([newDirectory], completion: nil)
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func pickImageFromLibrary(action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = true
            
            present(imagePicker, animated: true, completion: nil)
        }
        
    }

    func takeImageWithCamera(action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            let camera = UIImagePickerController()
            
            camera.allowsEditing = true
            camera.sourceType = UIImagePickerControllerSourceType.camera
            camera.delegate = self
            
            present(camera, animated: true, completion: nil)
        }
    }
    
    func moveFile(action: UIAlertAction) -> Void {
        if let index = self.selectedIndex {
            if let selectedFile = self.navigationManager.getSelectedFileAtRow(indexPath: IndexPath(row: index, section: 0)) {
                moveToolBar.isHidden = false
                
                list!.contentInset = UIEdgeInsetsMake(0, 0, moveToolBar.frame.size.height, 0)
                
                navigationManager.movingOptions.isMoving = true
                navigationManager.movingOptions.src = selectedFile.path
                navigationManager.movingOptions.file = navigationManager.getFileObjInCurrentDir(selectedFile.path)
            
                selectedIndex = nil
            }
        }
    }
    
    func deleteFile(action: UIAlertAction) -> Void {
        if let index = selectedIndex {
            if let selectedFile = navigationManager.getSelectedFileAtRow(indexPath: IndexPath(row: index, section: 0)) {
                networkManager.fdel([selectedFile.path]) { _ in
                	self.selectedIndex = nil
                }
            }
        }
    }
    
    func renameFile(action: UIAlertAction) -> Void {
        if let index = selectedIndex {
            if let selectedFile = navigationManager.getSelectedFileAtRow(indexPath: IndexPath(row: index, section: 0)) {
                let alert = UIAlertController(title: "Renommer l'élément", message: nil, preferredStyle: .alert)
                
                // TODO: bug here, selection does not work
                alert.addTextField { (textField) -> Void in
                    textField.becomeFirstResponder()
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                    textField.text = selectedFile.path.components(separatedBy: "/").last!
                }
                
                alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    
                    let input = alert.textFields![0] as UITextField
                    
                    // TODO: check input
                    
                    if let text = input.text {
                        var components = selectedFile.path.components(separatedBy: "/").dropFirst()
                        components = components.dropLast()
                        components.append(text)
                        
                        let newPath = "/" + components.joined(separator: "/")
                        self.navigationManager.movingOptions.src = selectedFile.path
                        self.navigationManager.movingOptions.dest = newPath
                        
                        self.networkManager.fmove(self.navigationManager.movingOptions) { _ in
                            self.selectedIndex = nil
                        }
                    }
                }))
                present(alert, animated: true, completion: nil)
        	}
        }
    }
    
    func addActions() {
        
        var cancelAction = ActionSheetsManager.buildCancelAction(handler: nil)
        
        // UPLOAD
        ActionSheetsManager.add(newActionSheetType: ActionSheet.upload, title: "Ajout d'un nouvel élément", message: nil)
        
        let newDir = ActionSheetsManager.buildDefaultAction(title: "Créer un dossier", handler: createNewDirectory)
        let uploadFromLibrary = ActionSheetsManager.buildDefaultAction(title: "Importer depuis mes photos et vidéos", handler: pickImageFromLibrary)
        let uploadFromCamera = ActionSheetsManager.buildDefaultAction(title: "Prendre avec l'appareil photo", handler: takeImageWithCamera)

        ActionSheetsManager.add(newAction: newDir, to: ActionSheet.upload)
        ActionSheetsManager.add(newAction: uploadFromLibrary, to: ActionSheet.upload)
        ActionSheetsManager.add(newAction: uploadFromCamera, to: ActionSheet.upload)
        ActionSheetsManager.add(newAction: cancelAction, to: ActionSheet.upload)
        
        // DIR ACTIONS
        cancelAction = ActionSheetsManager.buildCancelAction(handler: nil)
        
        ActionSheetsManager.add(newActionSheetType: ActionSheet.dirOpt, title: "Dossier", message: nil)
        
        let rename = ActionSheetsManager.buildDefaultAction(title: "Renommer", handler: renameFile)
        let move = ActionSheetsManager.buildDefaultAction(title: "Déplacer", handler: moveFile)
        let delete = ActionSheetsManager.buildDefaultAction(title: "Supprimer", handler: deleteFile)
        
        ActionSheetsManager.add(newAction: rename, to: ActionSheet.dirOpt)
        ActionSheetsManager.add(newAction: move, to: ActionSheet.dirOpt)
        ActionSheetsManager.add(newAction: delete, to: ActionSheet.dirOpt)
        ActionSheetsManager.add(newAction: cancelAction, to: ActionSheet.dirOpt)
        
        // FILE ACTIONS
        ActionSheetsManager.add(newActionSheetType: ActionSheet.fileOpt, title: "Fichier", message: nil)
        
        let download = ActionSheetsManager.buildDefaultAction(title: "Renommer", handler: nil) // TODO

        ActionSheetsManager.add(newAction: rename, to: ActionSheet.fileOpt)
        ActionSheetsManager.add(newAction: move, to: ActionSheet.fileOpt)
        ActionSheetsManager.add(newAction: delete, to: ActionSheet.fileOpt)
        ActionSheetsManager.add(newAction: download, to: ActionSheet.fileOpt)
		ActionSheetsManager.add(newAction: cancelAction, to: ActionSheet.fileOpt)
    }
    
    func uploadOptions() {
        if let actionSheet = ActionSheetsManager.getActionSheet(actionSheetType: ActionSheet.upload) {
            actionSheet.view.tintColor = STOREIT_RED
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    @IBAction func openContextualMenu(_ sender: AnyObject) {
        if let index = sender.tag {
            self.selectedIndex = sender.tag
            
            let isDir = self.navigationManager.isSelectedFileAtRowADir(indexPath: IndexPath(row: index, section: 0))
            let actionSheetType: ActionSheet = isDir ? ActionSheet.dirOpt : ActionSheet.fileOpt
            
            if let actionSheet = ActionSheetsManager.getActionSheet(actionSheetType: actionSheetType) {
                actionSheet.view.tintColor = STOREIT_RED
                present(actionSheet, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: move feature
    
    @IBAction func moveInCurrentDirectory(sender: AnyObject) {
        if let src = navigationManager.movingOptions.src {
            let targetPath = navigationManager.buildCurrentDirectoryPath()
			let fileName = src.components(separatedBy: "/").last!
            let dest = "\(targetPath)\(targetPath.characters.last! == "/" ? "" : "/" )\(fileName)"
            
            self.navigationManager.movingOptions.file?.path = dest
            self.navigationManager.movingOptions.dest = dest
            
            networkManager.fmove((self.navigationManager.movingOptions), completion: nil)
        }
    }
    
    @IBAction func cancelMove(_ sender: AnyObject) {
        moveToolBar.isHidden = true
        list!.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        navigationManager.movingOptions = MovingOptions()
    }
}
