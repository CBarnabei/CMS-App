//
//  CMSAttachmentContext.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 1/28/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import CloudKit

/// Provides access to attachments in Core Data.
class CMSAttachmentContext {
    
    private static let entityName = "CMSAttachment"
    
    static let folderName = "Attachments"
    
    static func fetchAll() throws -> [CMSAttachment] {
        do {
            return try CMSCoreDataBrain.itemsForPredicate(nil, forEntityName: entityName) as! [CMSAttachment]
        } catch { throw error }
    }
    
    static func dataFromAttachment(attachment: CMSAttachment) -> NSData? {
        return CMSFileBrain.readFileWithName("\(folderName)/\(attachment.fileName)")
    }
    
    private static func addAttachment(file: NSData, title: String, announcement: CMSAnnouncement?, recordIDName: String) throws -> CMSAttachment {
        
        // Validate
        guard !title.isEmpty else { throw CMSAttachmentError.EmptyTitle }
        guard file.length > 0 else { throw CMSAttachmentError.EmptyFile }
        
        // Any passed announcement must be valid.
        let validatedAnnouncement: CMSAnnouncement?
        if let providedAnnouncement = announcement {
            do {
                validatedAnnouncement = try CMSCoreDataBrain.itemInStorageForObject(providedAnnouncement, forEntityName: "CMSAnnouncement") as? CMSAnnouncement
            } catch { throw CMSAttachmentError.InvalidAnnouncement(announcement: providedAnnouncement) }
        } else { validatedAnnouncement = nil }
        
        let fileManager = NSFileManager.defaultManager()
        
        // Duplicate Protection
        var existingFileName: String? = nil
        let attachments = try fetchAll()
        for anAttachment in attachments {
            if let data = fileManager.contentsAtPath(CMSFileBrain.pathInDocumentsForFileName("\(folderName)/\(anAttachment.fileName)")) {
                if data.isEqualToData(file) {
                    existingFileName = anAttachment.fileName
                }
            }
        }
        
        // Write File
        let fileInfo: (fileName: String, convenienceTitle: String)
        if let existingName = existingFileName {
            fileInfo = (existingName, (title as NSString).stringByDeletingPathExtension)
        } else {
            do {
                fileInfo = try CMSFileBrain.writeFileAtomicallyToDisk(file, folderPath: folderName, name: title)
            } catch {
                NSLog("Error Writing File \(title): \(error.errorDetails)")
                throw CMSAttachmentError.FileWriteFailed
            }
        }
        
        // Create Core Data Object
        let attachment = try CMSCoreDataBrain.createCustomizableItemForEntity(entityName) as! CMSAttachment
        attachment.title = fileInfo.convenienceTitle
        attachment.fileName = fileInfo.fileName
        attachment.recordID = recordIDName
        attachment.announcement = validatedAnnouncement
        try CMSCoreDataBrain.saveContext()
        return attachment
        
    }
    
    private static func addAnnouncement(announcement: CMSAnnouncement, forAttachment attachment: CMSAttachment) throws {
        
        // Ensure passed values are stored.
        guard let validAnnouncement = try? CMSCoreDataBrain.itemInStorageForObject(announcement, forEntityName: "CMSAnnouncement") as! CMSAnnouncement else { throw CMSAttachmentError.InvalidAnnouncement(announcement: announcement) }
        guard let validAttachment = try? CMSCoreDataBrain.itemInStorageForObject(attachment, forEntityName: "CMSAttachment") as! CMSAttachment else { throw CMSAnnouncementError.InvalidAttachment(attachment: attachment) }
        
        // Add
        for att in validAnnouncement.attachments.allObjects as! [CMSAttachment] {
            if att.fileName == validAttachment.fileName {
                print("Avoided adding duplicate attachment to announcement.")
                return
            }
        }
        validAttachment.announcement = validAnnouncement
        
        // Save
        try CMSCoreDataBrain.saveContext()
        
        print("\"\(validAttachment.title)\" added to \"\(validAnnouncement.title)\"")
        
    }
    
    private static func deleteAttachment(attachment: CMSAttachment) throws {
        
        // Delete file
        let path = pathForFileName(attachment.fileName)
        print("exists?")
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            print("yes -- delete it")
            try CMSFileBrain.deleteFile(path: path)
        }
        
        // Delete Core Data Entry
        try CMSCoreDataBrain.deleteItem(attachment)
        
    }
    
    static func clean() throws {
        
        for attachment in try fetchAll() {
            let path = pathForFileName(attachment.fileName)
            if !NSFileManager.defaultManager().fileExistsAtPath(path) {
                try deleteAttachment(attachment)
            }
        }
        
    }
    
    static func wipe() throws {
        
        try CMSCoreDataBrain.deleteAllForEntity("CMSAttachment")
        
        // Wipe Attachments folder
        let attachmentsPath = CMSFileBrain.pathInDocumentsForFileName(folderName)
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(attachmentsPath)
        while let file = enumerator?.nextObject() as? String {
            try CMSFileBrain.deleteFile(path: (attachmentsPath as NSString).stringByAppendingPathComponent(file))
        }
        
    }
    
    static func pathForFileName(name: String) -> String {
        return CMSFileBrain.pathInDocumentsForFileName("\(CMSAttachmentContext.folderName)/\(name)")
    }
    
    // MARK: - iCloud Support
    
    static func addAttachment(record: CKRecord) throws {
        
        // Make sure the record represents an attachment.
        guard record.recordType == "Attachments" else { throw CMSCloudError.RecordOfWrongType }
        
        guard try CMSAnnouncementContext.announcementForRecordID((record["Announcement"] as! CKReference).recordID) != nil else { return }
        
        // Get values from record
        let title = record["Title"] as! String
        let asset = record["Attachment"] as! CKAsset
        let file = NSData(contentsOfURL: asset.fileURL)
        
        // Create Attachment
        if let attachmentFile = file {
            try addAttachment(attachmentFile, title: title, announcement: nil, recordIDName: record.recordID.recordName)
        } else {
            throw CMSCloudError.InvalidAssetUrlFromCloudKit
        }
        
    }
    
    static func addToAnnouncement(attachmentRecord attachmentRecord: CKRecord) throws {
        let announcement = attachmentRecord["Announcement"] as! CKReference
        print("Received anouncement reference for attachment.")
        try addAnnouncement(announcement, forAttachmentID: attachmentRecord.recordID)
    }
    
    private static func addAnnouncement(announcementReference: CKReference, forAttachmentID attachmentRecordID: CKRecordID) throws {
        
        let announcement = try CMSAnnouncementContext.announcementForRecordID(announcementReference.recordID)
        let attachment = try attachmentForRecordID(attachmentRecordID)
        
        if let storedAnnouncement = announcement, let storedAttachment = attachment {
            try addAnnouncement(storedAnnouncement, forAttachment: storedAttachment)
        }
        
    }
    
    static func attachmentForRecordID(recordID: CKRecordID) throws -> CMSAttachment? {
        let predicate = NSPredicate(format: "recordID == %@", argumentArray: [recordID.recordName])
        let attachments = try CMSCoreDataBrain.itemsForPredicate(predicate, forEntityName: "CMSAttachment")
        return attachments.isEmpty ? nil : (attachments[0] as! CMSAttachment)
    }
    
    private static func changeValue(forRecordID recordID: CKRecordID, changeValue: (CMSAttachment) throws -> () ) throws {
        
        let attachment: CMSAttachment! = try attachmentForRecordID(recordID)
        
        guard attachment != nil else { throw CMSAttachmentError.IDNotFound }
        
        try changeValue(attachment)
        
        try CMSCoreDataBrain.saveContext()
        
    }
    
    static func changeTitle(newTitle: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { attachment in
            attachment.title = newTitle
        }
    }
    
    static func changeFile(newFile: CKAsset, newTitle: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { attachment in
            let announcement = attachment.announcement
            try deleteAttachment(attachment)
            let data = NSData(contentsOfURL: newFile.fileURL)!
            try addAttachment(data, title: newTitle, announcement: announcement, recordIDName: recordID.recordName)
        }
    }
    
    static func changeAnnouncement(newAnnouncement: CKReference, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { _ in
            try self.addAnnouncement(newAnnouncement, forAttachmentID: recordID)
        }
    }
    
    static func deleteAttachment(recordID: CKRecordID) throws {
        
        let attachment = try attachmentForRecordID(recordID)
        
        if let attachmentToDelete = attachment {
            try deleteAttachment(attachmentToDelete)
        } else { throw CMSAttachmentError.IDNotFound }
        
    }
    
}