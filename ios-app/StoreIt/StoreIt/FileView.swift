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

    var data: Data? = nil
    
    let fileManager = Foundation.FileManager.default
    var tmpDirUrl: URL
    
    required init?(coder aDecoder: NSCoder) {
        // Creation of tmp dir
        let identifier = ProcessInfo.processInfo.globallyUniqueString
        self.tmpDirUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(identifier, isDirectory: true)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        self.clearTmpDir()
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    func presentQlPreviewController() {
        let QL = QLPreviewController()
        QL.dataSource = self
        QL.delegate = self
        
        self.navigationController?.present(QL, animated: false, completion: nil)
    }
    
    func showActivityIndicatory() {
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray

        self.view.addSubview(actInd)
        
        actInd.startAnimating()
    }
    
    // TODO: Try / Catch
    func clearTmpDir() {
        try! fileManager.removeItem(at: self.tmpDirUrl)
    }
    
    // TODO: Try / Catch
    func createTmpFile() -> URL? {

        if let unwrapData = self.data {

            // Creation of tmp file
            let fileName = self.navigationItem.title!
            try! self.fileManager.createDirectory(at: self.tmpDirUrl, withIntermediateDirectories: true, attributes: nil)
            
            let fileURL = self.tmpDirUrl.appendingPathComponent(fileName)
            
            // Write data to file
            try! unwrapData.write(to: fileURL, options: .atomicWrite)
            
            return fileURL
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
        return URL(string: "") as! QLPreviewItem // fix that later because it will crash, thx swift 3
    }
    
}
