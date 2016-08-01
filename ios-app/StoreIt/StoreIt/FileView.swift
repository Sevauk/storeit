//
//  FileView.swift
//  StoreIt
//
//  Created by Romain Gjura on 19/07/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import UIKit
import QuickLook

class FileView: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    var bytes: [UInt8]? = nil
    
    let fileManager = NSFileManager.defaultManager()
    var tmpDirUrl: NSURL
    
    required init?(coder aDecoder: NSCoder) {
        // Creation of tmp dir
        let identifier = NSProcessInfo.processInfo().globallyUniqueString
        self.tmpDirUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(identifier, isDirectory: true)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func previewControllerWillDismiss(controller: QLPreviewController) {
        self.clearTmpDir()
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    func presentQlPreviewController() {
        let QL = QLPreviewController()
        QL.dataSource = self
        QL.delegate = self
        
        self.navigationController?.presentViewController(QL, animated: false, completion: nil)
    }
    
    func showActivityIndicatory() {
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        
        actInd.frame = CGRectMake(0.0, 0.0, 40.0, 40.0)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray

        self.view.addSubview(actInd)
        
        actInd.startAnimating()
    }
    
    // TODO: Try / Catch
    func clearTmpDir() {
        try! fileManager.removeItemAtURL(self.tmpDirUrl)
    }
    
    // TODO: Try / Catch
    func createTmpFile() -> NSURL? {
        if let unwrapBytes = self.bytes {
            
            // Creation of tmp file
            let fileName = self.navigationItem.title!
            try! self.fileManager.createDirectoryAtURL(self.tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
            
            let fileURL = self.tmpDirUrl.URLByAppendingPathComponent(fileName)
            let data = NSData(bytes: unwrapBytes)
            
            // Write data to file
            try! data.writeToURL(fileURL, options: .AtomicWrite)
            
            return fileURL
        }
        return nil
    }
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController)  -> Int{
        return 1
    }
    
    func previewController(controller: QLPreviewController,
                             previewItemAtIndex index: Int) -> QLPreviewItem {
        if let doc = self.createTmpFile() {
            return doc
        }
    	return NSURL()
    }
    
}
