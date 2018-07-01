//
//  Downloader.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/28/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import AWSS3
import CoreML
import KeychainSwift

class Downloader {
    
    var managedObjectContext: NSManagedObjectContext?

    var downloadRequests = Array<AWSS3TransferManagerDownloadRequest?>()
    var downloadFileURLs = Array<URL?>()
    
    private func download(_ downloadRequest: AWSS3TransferManagerDownloadRequest) {
        switch (downloadRequest.state) {
        case .notStarted, .paused:
            let transferManager = AWSS3TransferManager.default()
            transferManager.download(downloadRequest).continueWith(block: { (task) -> AnyObject? in
                if let error = task.error as NSError? {
                    if error.domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.paused {
                        print("Download paused.")
                    } else {
                        print("download failed: [\(error)]")
                    }
                } else {
                    let result = task.result as! AWSS3TransferManagerDownloadOutput
                    
                    // compile core-data model
                    if let body = result.body as? String, body.range(of:".mlmodel") != nil {
                        if let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("download")?.appendingPathComponent("SpamClassifier.mlmodel") {
                            
                            let compiledUrl = try! MLModel.compileModel(at: url)
                            
                            let fileManager = FileManager.default
                            let appSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory,
                                                                           in: .userDomainMask, appropriateFor: compiledUrl, create: true)
                            // create a permanent URL in the app support directory
                            let permanentUrl = appSupportDirectory.appendingPathComponent(compiledUrl.lastPathComponent)
                            do {
                                try fileManager.aws_atomicallyCopyItem(at: compiledUrl, to: permanentUrl, backupItemName: "whocares")
                            } catch {
                                print("Error during copy: \(error.localizedDescription)")
                            }
                            
                        }
                    } else if let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("download")?.appendingPathComponent("SmsSpammers.json").path {
                        if let _ = KeychainSwift().get("plan") {
                            do {
                                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let numbers = jsonResult["data"] as? [[String : Any]] {
                                    for number in numbers {
                                        if let managedObjectContext = self.managedObjectContext {
                                            managedObjectContext.perform {
                                                if let num = number["value"] as? String {
                                                    let item = Item(context: managedObjectContext)
                                                    item.createdAt = Date()
                                                    item.updatedAt = Date()
                                                    item.title = num
                                                    item.type = "phone"
                                                    item.category = "blocked"
                                                    item.hidden = true
                                                }
                                                
                                                try! managedObjectContext.save()
                                            }
                                        }
                                    }
                                }
                            } catch {
                                // handle error
                            }
                        }
                    }
                }
                
                return nil
            })
            
            break
        default:
            break
        }
    }
    
    private func downloadAll() {
        for (_, value) in self.downloadRequests.enumerated() {
            if let downloadRequest = value {
                if downloadRequest.state == .notStarted
                    || downloadRequest.state == .paused {
                    self.download(downloadRequest)
                }
            }
        }
    }
    
    func downloadDetectionData() {
        
        // Create directory to store the model + SMS messages
        do {
            try FileManager.default.createDirectory(
                at: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("download"),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            print("Creating 'download' directory failed. Error: \(error)")
        }
        
        let s3 = AWSS3.default()
        
        let listObjectsRequest = AWSS3ListObjectsRequest()
        listObjectsRequest?.bucket = S3BucketName
        s3.listObjects(listObjectsRequest!).continueWith { (task) -> AnyObject? in
            if let error = task.error {
                print("listObjects failed: [\(error)]")
            }
            
            if let listObjectsOutput = task.result {
                if let contents = listObjectsOutput.contents {
                    for s3Object in contents {
                        let downloadingFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("download")?.appendingPathComponent(s3Object.key!)
                        let downloadingFilePath = downloadingFileURL?.path
                        
                        if FileManager.default.fileExists(atPath: downloadingFilePath!) {
                            self.downloadRequests.append(nil)
                            self.downloadFileURLs.append(downloadingFileURL)
                        } else {
                            let downloadRequest = AWSS3TransferManagerDownloadRequest()
                            downloadRequest?.bucket = S3BucketName
                            downloadRequest?.key = s3Object.key
                            downloadRequest?.downloadingFileURL = downloadingFileURL
                            
                            self.downloadRequests.append(downloadRequest)
                            self.downloadFileURLs.append(nil)
                        }
                    }
                    
                    self.downloadAll()
                }
            }
            
            return nil
        }
    }
}
