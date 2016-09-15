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

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadOptions))
        
        self.actionSheetsManager = ActionSheetsManager()
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.upload, title: "Ajout d'un nouvel élément", message: nil)
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.dir_OPT, title: "Dossier", message: "Que voulez-vous faire ?")
        self.actionSheetsManager!.addNewActionSheet(ActionSheets.file_OPT, title: "Fichier", message: "Que voulez-vous faire ?")
        self.addActionsToActionSheets()
    }
    
    // function triggered when back button of navigation bar is pressed
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        if (parent == nil) {
            self.navigationManager?.goPreviousDir()
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    	self.moveToolBar.isHidden = !(self.navigationManager?.movingOptions.isMoving)!
        
        self.navigationManager?.list = self.list
        self.navigationManager?.moveToolBar = self.moveToolBar

        self.list.reloadData()
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
        
        //let target: File? = sender as? File

        if let target: File = sender as? File {
            if (segue.identifier == "nextDirSegue") {
                
                let listView = (segue.destination as! StoreItSynchDirectoryView)
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
                let fileView = segue.destination as! FileView
                
                fileView.navigationItem.title = self.navigationManager?.getTargetName(target)
                fileView.showActivityIndicatory()

                self.ipfsManager?.get(target.IPFSHash) { data in
                    fileView.data = data
                    fileView.presentQlPreviewController()
                }
            }
        }
    }

	// MARK: Creation and management of table cells
    
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.navigationManager?.getSortedItems().count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createItemCellAtIndexPath(indexPath)
    }
    
    // Function triggered when a cell is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFile: File = (navigationManager?.getSelectedFileAtRow(indexPath))!
        let isDir: Bool = (self.navigationManager?.isSelectedFileAtRowADir(indexPath))!

        if (isDir) {
            self.performSegue(withIdentifier: "nextDirSegue", sender: selectedFile)
        } else {
            self.performSegue(withIdentifier: "showFileSegue", sender: selectedFile)
        }
    }
    
    func createItemCellAtIndexPath(_ indexPath: IndexPath) -> UITableViewCell {
        let isDir: Bool = (self.navigationManager?.isSelectedFileAtRowADir(indexPath))!
        let items: [String] = (self.navigationManager?.getSortedItems())!
                
        if (isDir) {
            let cell = self.list.dequeueReusableCell(withIdentifier: CellIdentifiers.Directory.rawValue) as! DirectoryCell
            cell.itemName.text = "\(items[(indexPath as NSIndexPath).row])"
            cell.contextualMenu.tag = (indexPath as NSIndexPath).row
            return cell
        } else {
            let cell = self.list.dequeueReusableCell(withIdentifier: CellIdentifiers.File.rawValue) as! FillCell
            cell.itemName.text = "\(items[(indexPath as NSIndexPath).row])"
            cell.contextualMenu.tag = (indexPath as NSIndexPath).row
            return cell
        }
    }

    // MARK: Action sheet creation and management
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        self.dismiss(animated: true, completion: {_ in
            let referenceUrl = editingInfo["UIImagePickerControllerReferenceURL"] as! URL
            let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil).firstObject as! PHAsset

            PHImageManager.default().requestImageData(for: asset, options: PHImageRequestOptions(), resultHandler: {
                (imagedata, dataUTI, orientation, info) in
                if info!.keys.contains(NSString(string: "PHImageFileURLKey"))
                {
                    let filePath = info![NSString(string: "PHImageFileURLKey")] as! URL
                    
                    // Maybe begin some loading in interface here...
                    self.ipfsManager?.add(filePath) {
                        (
                        data, response, error) in
                        
                        guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                            print("[IPFS.ADD] Error while IPFS ADD: \(error)")
                            return
                        }

                        // If ipfs add succeed
                        let dataString = NSString(data: data!, encoding: String.Encoding.utf8)!
                        let ipfsAddResponse = Mapper<IpfsAddResponse>().map(dataString)
                        let relativePath = self.navigationManager?.buildPath(filePath.lastPathComponent!)
                        
						let file = self.fileManager?.createFile(relativePath!, metadata: "", IPFSHash: ipfsAddResponse!.hash)
 
                        self.networkManager?.fadd([file!], completion: nil)
                    }
                }
            })
        });
    }
    
    func createNewDirectory(_ action: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Création de dossier", message: "Entrez le nom du dossier", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            let input = alert.textFields![0] as UITextField

        	// TODO: check input
            
            let relativePath = self.navigationManager?.buildPath(input.text!)
            let newDirectory: File = self.fileManager!.createDir(relativePath!, metadata: "", IPFSHash: "")

            self.networkManager?.fadd([newDirectory], completion: nil)
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func pickImageFromLibrary(_ action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        }
        
    }

    func takeImageWithCamera(_ action: UIAlertAction) -> Void {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            let camera = UIImagePickerController()
            
            camera.allowsEditing = true
            camera.sourceType = UIImagePickerControllerSourceType.camera
            camera.delegate = self
            
            self.present(camera, animated: true, completion: nil)
        }
    }
    
    func moveFile(_ action: UIAlertAction) -> Void {
        if let index = self.lastSelectedActionSheetForFile {
        	if let selectedFile = self.navigationManager?.getSelectedFileAtRow(IndexPath(row: index, section: 0)) {
                self.moveToolBar.isHidden = false
                
                self.list!.contentInset = UIEdgeInsetsMake(0, 0, self.moveToolBar.frame.size.height, 0)
                
                self.navigationManager?.movingOptions.isMoving = true
                self.navigationManager?.movingOptions.src = selectedFile.path
                self.navigationManager?.movingOptions.file = self.navigationManager?.getFileObjInCurrentDir(selectedFile.path)
            
                self.lastSelectedActionSheetForFile = nil
            }
        }
    }
    
    func deleteFile(_ action: UIAlertAction) -> Void {
        if let index = self.lastSelectedActionSheetForFile {
            if let selectedFile = navigationManager?.getSelectedFileAtRow(IndexPath(row: index, section: 0)) {
                self.networkManager?.fdel([selectedFile.path], completion: nil)
            }
        }
    }
    
    func renameFile(_ action: UIAlertAction) -> Void {
        if let index = self.lastSelectedActionSheetForFile {
            if let selectedFile = self.navigationManager?.getSelectedFileAtRow(IndexPath(row: index, section: 0)) {
            let alert = UIAlertController(title: "Renommer l'élément", message: nil, preferredStyle: .alert)
            
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
                    self.navigationManager?.movingOptions.src = selectedFile.path
                    self.navigationManager?.movingOptions.dest = newPath
                    
                    self.networkManager?.fmove((self.navigationManager?.movingOptions)!, completion: nil)
                    
                    self.lastSelectedActionSheetForFile = nil
        
                }
        	}))
        	self.present(alert, animated: true, completion: nil)
        	}
        }
    }

    func addActionsToActionSheets() {
        if let ASManager = self.actionSheetsManager {

            // Main Action Sheet (Upload)
            let uploadAS = ActionSheets.upload
            var uploadActions: [String:((UIAlertAction) -> Void)?] = [:]
            
            uploadActions["Créer un dossier"] = createNewDirectory
            uploadActions["Importer depuis mes photos et vidéos"] = pickImageFromLibrary
            uploadActions["Prendre avec l'appareil photo"] = takeImageWithCamera
            
            // Dir actions Action Sheet
            let dirAS = ActionSheets.dir_OPT
            var fileActions: [String:((UIAlertAction) -> Void)?] = [:]
            
            fileActions["Renommer"] = renameFile
            fileActions["Déplacer"] = moveFile
            fileActions["Supprimer"] = deleteFile
            
            // File actions Action Sheet
            let fileAS = ActionSheets.file_OPT
            
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
        if let actionSheet = self.actionSheetsManager?.getActionSheet(ActionSheets.upload) {
            self.present(actionSheet, animated: true, completion: nil)

        }
    }
    
    func openContextualMenu() {
        if let index = self.lastSelectedActionSheetForFile {
            if let isDir = self.navigationManager?.isSelectedFileAtRowADir(IndexPath(row: index, section: 0)) {
                let actionSheetType: ActionSheets = isDir ? ActionSheets.dir_OPT : ActionSheets.file_OPT
                
                if let actionSheet = self.actionSheetsManager?.getActionSheet(actionSheetType) {
                    self.present(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func openContextualMenu(_ sender: AnyObject) {
        self.lastSelectedActionSheetForFile = sender.tag
        self.openContextualMenu()
    }
    
    
    // MARK: move feature
    
    @IBAction func moveInCurrentDirectory(_ sender: AnyObject) {
        if let src = navigationManager?.movingOptions.src {
            let targetPath = navigationManager?.buildCurrentDirectoryPath()
			let fileName = src.components(separatedBy: "/").last!
            let dest = "\(targetPath!)\(targetPath?.characters.last! == "/" ? "" : "/" )\(fileName)"
            
            self.navigationManager?.movingOptions.file?.path = dest
            self.navigationManager?.movingOptions.dest = dest
            
            self.networkManager?.fmove((self.navigationManager?.movingOptions)!, completion: nil)
        }
        
    }
    
    @IBAction func cancelMove(_ sender: AnyObject) {
        self.moveToolBar.isHidden = true
        self.list!.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.navigationManager?.movingOptions = MovingOptions()
    }
}
