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
    
    let networkManager = NetworkManager.shared
    let navigationManager = NavigationManager.shared
    let offlineManager = OfflineManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        list.delegate = self
        list.dataSource = self

    	navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
    	                                                    target: self,
    	                                                    action: #selector(uploadOptions))
    }
    
    // function triggered when back button of navigation bar is pressed
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
        if (parent == nil) {
            navigationManager.goBack()
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
    
    // MARK: SEGUE MANAGEMENT
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false // segues are triggered manually
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target: File = sender as? File {
            if (segue.identifier == "nextDirSegue") {
                
                let listView = (segue.destination as! SynchDirView)
                _ = navigationManager.go(to: target)
                
                listView.navigationManager.movingOptions.isMoving = navigationManager.movingOptions.isMoving
            }
                
            // TODO: TRY WITHOUT FILE VIEW (PRESENT QL HERE)
            else if (segue.identifier == "showFileSegue") {
                let fileView = segue.destination as! FileView
                
                fileView.navigationItem.title = navigationManager.getName(for: target)
                fileView.showActivityIndicatory()

                let offlineActivated = navigationManager.isOfflineActivated(for: target.IPFSHash)
                
                if (offlineActivated) {
                    print("GETTING DATA WITH OFFLINE MODE FOR HASH : \(target.IPFSHash)")
                    
                    fileView.data = offlineManager.getData(for: target.IPFSHash, at: target.path)
                    fileView.navigationControllerCopy = self.navigationController
                    fileView.presentQlPreviewController()
                } else {
                    print("GETTING DATA WITH IPFS FOR HASH : \(target.IPFSHash)")
                    
                    IpfsManager.get(hash: target.IPFSHash) { data in
                        fileView.data = data
                        fileView.navigationControllerCopy = self.navigationController
                        fileView.presentQlPreviewController()
                    }
                }
            }
        }
    }

	// MARK: TABLE VIEW MANAGEMENT
    
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return navigationManager.getSortedItems().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createCell(at: indexPath)
    }
    
    // Function triggered when a cell is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedFile: File = navigationManager.getFile(at: indexPath) {
            let isDir: Bool = navigationManager.isFileADir(at: indexPath)
            
            if (isDir) {
                performSegue(withIdentifier: "nextDirSegue", sender: selectedFile)
            } else {
                performSegue(withIdentifier: "showFileSegue", sender: selectedFile)
            }
        }
    }
    
    func createCell(at indexPath: IndexPath) -> UITableViewCell {
        let isDir: Bool = navigationManager.isFileADir(at: indexPath)
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

    // MARK: ACTION SHEET MANAGEMENT
    
    enum ActionSheet {
        case directory
        case file
        case upload
    }
    
    func buildAction(title: String, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
    
    func buildFileActionSheet(title: String, message: String) -> UIAlertController {
        let rename = buildAction(title: "Renommer", style: .default, handler: renameFile)
        let move = buildAction(title: "Déplacer", style: .default, handler: moveFile)
        let delete = buildAction(title: "Supprimer", style: .default, handler: deleteFile)
        let cancel = buildAction(title: "Annuler", style: .cancel, handler: nil)
        
        var offline: UIAlertAction?
        
        if let index = selectedIndex {
            if let selectedFile = navigationManager.getFile(at: IndexPath(row: index, section: 0)) {
                
                if (!selectedFile.isDir) {
                    let offlineActivated = navigationManager.isOfflineActivated(for: selectedFile.IPFSHash)
                    
                    if (offlineActivated) {
                        offline = buildAction(title: "Désactiver le mode hors ligne pour ce fichier",
                                              style: .default,
                                              handler: deactivateOfflineForFile)
                    } else {
                        offline = buildAction(title: "Activer le mode hors ligne pour ce fichier",
                                              style: .default,
                                              handler: activateOfflineForFile)
                    }
                }
            }
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(rename)
        alertController.addAction(move)
        alertController.addAction(delete)
        
        if let offline = offline {
            alertController.addAction(offline)
        }
        
        alertController.addAction(cancel)
        
        return alertController
    }
    
    func buildUploadActionSheet() -> UIAlertController {
        let newDirectory = buildAction(title: "Créer un dossier", style: .default, handler: createNewDirectory)
        let uploadFromLibrary = buildAction(title: "Importer depuis mes photos et vidéos", style: .default, handler: pickImageFromLibrary)
        let uploadFromCamera = buildAction(title: "Prendre avec l'appareil photo", style: .default, handler: takeImageWithCamera)
        let cancel = buildAction(title: "Annuler", style: .cancel, handler: nil)
        
        let alertController = UIAlertController(title: "Ajout d'un nouvel élément", message: "Choisissez une option", preferredStyle: .actionSheet)
        
        alertController.addAction(newDirectory)
        alertController.addAction(uploadFromLibrary)
        alertController.addAction(uploadFromCamera)
        alertController.addAction(cancel)
        
        return alertController
    }
    
    func buildActionSheet(for type: ActionSheet) -> UIAlertController {
        switch type {
            
        case .directory:
            return buildFileActionSheet(title: "Dossier", message: "Que voulez-vous faire ?")
            
        case .file:
            return buildFileActionSheet(title: "Fichier", message: "Que voulez-vous faire ?")
            
        case .upload:
            return buildUploadActionSheet()
        }
        
    }
    
    func uploadOptions() {
        let actionSheet = buildActionSheet(for: .upload)
        
        actionSheet.view.tintColor = LIGHT_GREY
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func openContextualMenu(_ sender: AnyObject) {
        if let index = sender.tag {
            self.selectedIndex = sender.tag
            
            let isDir = navigationManager.isFileADir(at: IndexPath(row: index, section: 0))
            let actionSheet = isDir ? buildActionSheet(for: .directory) : buildActionSheet(for: .file)
            
            actionSheet.view.tintColor = LIGHT_GREY
            present(actionSheet, animated: true, completion: nil)
        }
    }

    
    // MARK: ACTION SHEET HANDLERS
    
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
                            let relativePath = self.navigationManager.buildPath(for: filePath.lastPathComponent)
                            
                            let file = self.navigationManager.createFile(path: relativePath, metadata: "", IPFSHash: ipfsAddResponse!.hash)
                            
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
            
            let relativePath = self.navigationManager.buildPath(for: input.text!)
            let newDirectory: File = self.navigationManager.createDir(path: relativePath, metadata: "", IPFSHash: "")

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
        selectedFile { file in
            moveToolBar.isHidden = false
            
            list!.contentInset = UIEdgeInsetsMake(0, 0, moveToolBar.frame.size.height, 0)
            
            navigationManager.movingOptions.isMoving = true
            navigationManager.movingOptions.src = file.path
            navigationManager.movingOptions.file = navigationManager.getFileInCurrentDir(at: file.path)
            
            selectedIndex = nil
        }
    }
    
    func deleteFile(action: UIAlertAction) -> Void {
        selectedFile { file in
            networkManager.fdel([file.path]) { _ in
                self.selectedIndex = nil
            }
        }
    }
    
    func renameFile(action: UIAlertAction) -> Void {
        selectedFile { file in
            let alert = UIAlertController(title: "Renommer l'élément", message: nil, preferredStyle: .alert)
            
            // TODO: bug here, selection does not work
            alert.addTextField { (textField) -> Void in
                textField.becomeFirstResponder()
                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                textField.text = file.path.components(separatedBy: "/").last!
            }
            
            alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                
                let input = alert.textFields![0] as UITextField
                
                // TODO: check input
                
                if let text = input.text {
                    var components = file.path.components(separatedBy: "/").dropFirst()
                    components = components.dropLast()
                    components.append(text)
                    
                    let newPath = "/" + components.joined(separator: "/")
                    self.navigationManager.movingOptions.src = file.path
                    self.navigationManager.movingOptions.dest = newPath
                    
                    self.networkManager.fmove(self.navigationManager.movingOptions) { _ in
                        self.selectedIndex = nil
                    }
                }
            }))
            
            alert.view.tintColor = LIGHT_GREY
            
            present(alert, animated: true, completion: nil)
        }
    }

    func activateOfflineForFile(action: UIAlertAction) -> Void {
        selectedFile { file in
            print("Getting ipfs data ...")
            
            IpfsManager.get(hash: file.IPFSHash) { data in
                if let data = data {
                    self.offlineManager.write(hash: file.IPFSHash, to: file.path, content: data)
                    self.navigationManager.addToCurrentHashes(hash: file.IPFSHash)
                } else {
                    print("Could not get ipfs data for file with hash \(file.IPFSHash)")
                }
            }
        }
    }
    
    func deactivateOfflineForFile(action: UIAlertAction) -> Void {
        selectedFile { file in
            let removeSuccessful = self.offlineManager.remove(hash: file.IPFSHash, at: file.path)
            
            if (removeSuccessful) {
                self.navigationManager.removeFromCurrentHashes(hash: file.IPFSHash)
            }
        }
    }
    
    // MARK: MOVE FEATURE
    
    @IBAction func moveInCurrentDirectory(_ sender: AnyObject) {
        if let src = navigationManager.movingOptions.src {
            let targetPath = navigationManager.buildCurrentDirectoryPath()
			let fileName = src.components(separatedBy: "/").last!
            let dest = "\(targetPath)\(targetPath.characters.last! == "/" ? "" : "/" )\(fileName)"
            
            navigationManager.movingOptions.file?.path = dest
            navigationManager.movingOptions.dest = dest
            
            networkManager.fmove((navigationManager.movingOptions), completion: nil)
        }
    }
    
    @IBAction func cancelMove(_ sender: AnyObject) {
        moveToolBar.isHidden = true
        list!.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        navigationManager.movingOptions = MovingOptions()
    }
    
    // MARK: UTILS
    
    func selectedFile(handler: (File) -> Void) {
        if let index = selectedIndex {
            if let file = navigationManager.getFile(at: IndexPath(row: index, section: 0)) {
                handler(file)
            }
        }
    }
}
