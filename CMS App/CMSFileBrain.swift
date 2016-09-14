//
//  CMSFileBrain.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/4/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import CloudKit

class CMSFileBrain {
    
    static func pathInDocumentsForFileName(name: String) -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        return (documentDirectory as NSString).stringByAppendingPathComponent(name)
    }
    
    static func urlInDocumentsForFileName(name: String) -> NSURL {
        let path = pathInDocumentsForFileName(name)
        return NSURL.fileURLWithPath(path, isDirectory: false)
    }
    
    static func createFolder(path: String) throws {
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
    }
    
    static func writeFileAtomicallyToDisk(file: NSData, folderPath: String = "", name: String, failIfFirstAttempedPathExists: Bool = false) throws -> (fileName: String, convenienceTitle: String) {
        
        let fileManager = NSFileManager.defaultManager()
        
        // Create File Path
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileExtension = (name as NSString).pathExtension
        let realTitle = (name as NSString).stringByDeletingPathExtension
        var fileName = ""
        var filePath = ""
        var namingIteration = 0
        repeat {
            fileName = "\(realTitle)\(namingIteration == 0 ? "" : " \(namingIteration)").\(fileExtension)"
            filePath = (documentsDirectory as NSString).stringByAppendingPathComponent(folderPath)
            filePath = (filePath as NSString).stringByAppendingPathComponent(fileName)
            namingIteration += 1
            if failIfFirstAttempedPathExists && fileManager.fileExistsAtPath(filePath) { throw CMSFileError.FileAlreadyExists }
        } while fileManager.fileExistsAtPath(filePath)
        
        // Write File
        do {
            let url = NSURL.fileURLWithPath(filePath, isDirectory: false)
            try file.writeToURL(url, options: .DataWritingAtomic)
        } catch { throw error }
        
        return (fileName, realTitle)
        
    }
    
    static func readFileAtPath(path: String) -> NSData? {
        return NSFileManager.defaultManager().contentsAtPath(path)
    }
    
    static func readFileWithName(name: String) -> NSData? {
        let path = pathInDocumentsForFileName(name)
        return readFileAtPath(path)
    }
    
    static func deleteFile(path path: String) throws {
        
        // Delete From Hard Drive
        do {
            let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
            try NSFileManager.defaultManager().removeItemAtURL(fileURL)
        } catch {
            NSLog("Error Deleting File \"\(path)\": \(error.errorDetails)")
            throw error
        }
        
    }
    
}