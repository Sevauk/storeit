//
//  FileView.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import QuickLook
import APESuperHUD

class FileView: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    var data: Data? = nil
    var navigationControllerCopy: UINavigationController?
    
    let fileManager = Foundation.FileManager.default
    var tmpDirUrl: URL
    
    required init?(coder aDecoder: NSCoder) {
        // Creation of tmp dir
        let identifier = ProcessInfo.processInfo.globallyUniqueString
        tmpDirUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier, isDirectory: true)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    	super.viewWillAppear(animated)
        
        
    }
    
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        clearTmpDir()
		_ = navigationController?.popViewController(animated: false)
    }
    
    func presentQlPreviewController() {
        let QL = QLPreviewController()
        
        QL.dataSource = self
        QL.delegate = self

        // Use of a copy of navigationController because sometimes it's not init yet (offline mode: getting data to quickly)
        navigationControllerCopy?.present(QL, animated: false, completion: nil)
    }
    
    func showActivityIndicatory() {
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray

        view.addSubview(actInd)
        
        actInd.startAnimating()
    }
    
    func clearTmpDir() {
        try! fileManager.removeItem(at: self.tmpDirUrl)
    }
    
    func createTmpFile() -> URL? {
        if let unwrapData = data {
            // Creation of tmp file
            let fileName = navigationItem.title!
            
            do {
            	try fileManager.createDirectory(at: tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
            	let fileURL = tmpDirUrl.appendingPathComponent(fileName)
                
                // Write data to file
                try unwrapData.write(to: fileURL, options: .atomicWrite)
                
                return fileURL
            } catch {
            	print("ERROR: while creating temporary file for QLPreviewController")
            }
            
        }
        return nil
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController)  -> Int{
        return 1
    }
    
    func previewController(_ controller: QLPreviewController,
                             previewItemAt index: Int) -> QLPreviewItem {
        if let doc = self.createTmpFile() {
            return doc as QLPreviewItem
        }
        return URL(fileURLWithPath: "") as QLPreviewItem
    }
    
}
