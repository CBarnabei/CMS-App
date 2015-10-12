//
//  CMSAnnouncementContext.swift
//  CMS App
//
//  Created by App Development on 10/5/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

class CMSAnnouncementContext: CMSObjectContext {
    
    static let entityName = "CMSAnnouncement"
    
    static func fetchAll() throws -> [CMSAnnouncement] {
        do {
            return try CMSCoreDataBrain.itemsForPredicate(nil, forEntityName: entityName) as! [CMSAnnouncement]
        } catch { throw error }
    }
    
    static func addAnnouncement(title: String, text: String, attachments: [CMSAttachment] = []) throws -> CMSAnnouncement {
        
        // Validate Strings
        guard title.isValidAttributeValue() else { throw CMSAnnouncementError.EmptyTitle }
        guard text.isValidAttributeValue() else { throw CMSAnnouncementError.EmptyBody }
        
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
            announcement.formattedText = text
            announcement.attachments = Set(validatedAttachments)
            try CMSCoreDataBrain.saveContext()
            return announcement
        } catch { throw error }
    }
    
}