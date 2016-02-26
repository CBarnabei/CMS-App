//
//  CMSAnnouncementContext.swift
//  CMS App
//
//  Created by App Development on 10/5/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import CloudKit

class CMSAnnouncementContext {
    
    private static let entityName = "CMSAnnouncement"
    
    static func fetchAnnouncements(categoryKeys: [String]? = nil) throws -> [CMSAnnouncement] {
        
        if let requestedCategories = categoryKeys {
            
            var subPredicates = [NSPredicate]()
            for categoryKey in requestedCategories {
                let predicate = NSPredicate(format: "category == %@", argumentArray: [categoryKey])
                subPredicates.append(predicate)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
            return try CMSCoreDataBrain.itemsForPredicate(compoundPredicate, forEntityName: entityName) as! [CMSAnnouncement]
        } else {
            return try CMSCoreDataBrain.itemsForPredicate(nil, forEntityName: entityName) as! [CMSAnnouncement]
        }
        
    }
    
    private static func addAnnouncement(title: String, body: String, categoryKey: String, startDate: NSDate = NSDate(), endDate: NSDate, attachments: [CMSAttachment] = [], recordID: CKRecordID) throws -> CMSAnnouncement {
        
        // Validate Strings
        guard !title.isEmpty else { throw CMSAnnouncementError.EmptyTitle }
        guard !body.isEmpty else { throw CMSAnnouncementError.EmptyBody }
        
        // #warning uncomment below before release version
        //guard startDate.compare(NSDate()) != NSComparisonResult.OrderedAscending else { throw CMSAnnouncementError.InvalidDate(date: dateStamp) }
        
        // Validate Attachments
        let validatedAttachments: [CMSAttachment]
        do {
            validatedAttachments = try attachments.map {
                do {
                    return try CMSCoreDataBrain.itemInStorageForObject($0, forEntityName: "CMSAttachment") as! CMSAttachment
                } catch { throw CMSAnnouncementError.InvalidAttachment(attachment: $0) }
            }
        } catch { throw error }
        
        // Duplicate Protection
        let searchPredicate = NSPredicate(format: "title == %@", argumentArray: [title])
        let duplicates = try CMSCoreDataBrain.itemsForPredicate(searchPredicate, forEntityName: entityName)
        guard duplicates.isEmpty else { throw CMSAnnouncementError.DuplicateAnnouncement }
        
        // Create Announcement
        let announcement = try CMSCoreDataBrain.createCustomizableItemForEntity(entityName) as! CMSAnnouncement
        announcement.title = title
        announcement.formattedText = body
        announcement.category = categoryKey
        announcement.attachments = Set(validatedAttachments)
        announcement.startDate = startDate
        announcement.endDate = endDate.dateRetainingComponents(unitFlags: [.Month, .Day, .Year])
        announcement.recordID = recordID.recordName
        
        try CMSCoreDataBrain.saveContext()
        return announcement
    }
    
    private static func deleteAnnouncement(announcement: CMSAnnouncement) {
        try! CMSCoreDataBrain.deleteItem(announcement)
    }
    
    static func deleteAll() throws {
        try CMSCoreDataBrain.deleteAllForEntity(entityName)
    }
    
    
    // MARK: - iCloud Support
    
    static func addAnnouncement(record: CKRecord) throws {
        
        // Make sure the record is an Announcement
        guard record.recordType == "Announcements" else { throw CMSCloudError.RecordOfWrongType }
        
        // Get values
        let title = record["Title"] as! String
        let body = record["BodyText"] as! String
        let category = record["Category"] as! String
        let startDate = record["StartDate"] as! NSDate
        let endDate = record["EndDate"] as! NSDate
        let recordID = record.recordID
        
        // Create announcement
        try addAnnouncement(title, body: body, categoryKey: category, startDate: startDate, endDate: endDate, attachments: [], recordID: recordID)
        
    }
    
    static func announcementForRecordID(recordID: CKRecordID) throws -> CMSAnnouncement? {
        let predicate = NSPredicate(format: "recordID == %@", argumentArray: [recordID.recordName])
        let announcements = try CMSCoreDataBrain.itemsForPredicate(predicate, forEntityName: "CMSAnnouncement")
        return announcements.isEmpty ? nil : (announcements[0] as! CMSAnnouncement)
    }
    
    private static func changeValue(forRecordID recordID: CKRecordID, changeValue: (CMSAnnouncement) -> () ) throws {
        
        let announcement: CMSAnnouncement! = try announcementForRecordID(recordID)
        
        guard announcement != nil else { throw CMSAnnouncementError.IDNotFound }
        
        changeValue(announcement)
        
        try CMSCoreDataBrain.saveContext()
        
    }
    
    static func changeTitle(newTitle: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { announcement in
            announcement.title = newTitle
        }
    }
    
    static func changeBody(newBody: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { announcement in
            announcement.formattedText = newBody
        }
    }
    
    static func changeCategory(newCategoryKey newCategoryKey: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { announcement in
            announcement.category = newCategoryKey
        }
    }
    
    static func changeStartDate(newStartDate: NSDate, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { announcement in
            announcement.startDate = newStartDate
        }
    }
    
    static func changeEndDate(newEndDate: NSDate, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { announcement in
            announcement.endDate = newEndDate
        }
    }
    
    static func deleteAnnouncement(recordID: CKRecordID) throws {
        
        let announcement = try announcementForRecordID(recordID)
        
        if let announcementToDelete = announcement {
            deleteAnnouncement(announcementToDelete)
        } else { throw CMSAnnouncementError.IDNotFound }
        
    }
    
}