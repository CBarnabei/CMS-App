//
//  CMSAnnouncementContext.swift
//  CMS App
//
//  Created by App Development on 10/5/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

enum CMSAnnouncementCategory: String {
    case General = "General"
    case Birthdays = "Birthdays"
    case Sports = "Sports"
    case Clubs = "Clubs"
    case Counselor = "Counselor"
    case Principal = "Principal"
    case Nurse = "Nurse"
    case SSB = "Student School Board"
    case Graduation = "Graduation"
    case PTSA = "PTSA"
    case FCCTC = "FCCTC"
    case Other = "Other"
}

class CMSAnnouncementContext {
    
    static let entityName = "CMSAnnouncement"
    
    static func fetchAnnouncements(categoryKeys: [CMSAnnouncementCategoryKey]? = nil) throws -> [CMSAnnouncement] {
        
        if let requestedCategories = categoryKeys {
            
            var subPredicates = [NSPredicate]()
            for categoryKey in requestedCategories {
                let predicate = NSPredicate(format: "category == %@", argumentArray: [categoryKey.rawValue])
                subPredicates.append(predicate)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
            return try CMSCoreDataBrain.itemsForPredicate(compoundPredicate, forEntityName: entityName) as! [CMSAnnouncement]
        } else {
            return try CMSCoreDataBrain.itemsForPredicate(nil, forEntityName: entityName) as! [CMSAnnouncement]
        }
        
    }
    
    static func addAnnouncement(title: String, body: String, category: CMSAnnouncementCategory, endDate: NSDate, attachments: [CMSAttachment] = []) throws -> CMSAnnouncement {
        
        // Validate Strings
        guard !title.isEmpty else { throw CMSAnnouncementError.EmptyTitle }
        guard !body.isEmpty else { throw CMSAnnouncementError.EmptyBody }
        
        // Validate Attachments
        let validatedAttachments: [CMSAttachment]
        do {
            validatedAttachments = try attachments.map {
                do {
                    return try CMSCoreDataBrain.itemInStorageForObject($0, forEntityName: entityName) as! CMSAttachment
                } catch { throw CMSAnnouncementError.InvalidAttachment(attachment: $0) }
            }
        } catch { throw error }
        
        // Create Announcement
        do {
            let announcement = try CMSCoreDataBrain.createCustomizableItemForEntity(entityName) as! CMSAnnouncement
            announcement.title = title
            announcement.formattedText = body
            announcement.category = category.rawValue
            announcement.endDate = endDate
            announcement.attachments = Set(validatedAttachments)
            try CMSCoreDataBrain.saveContext()
            return announcement
        } catch { throw error }
    }
    
}