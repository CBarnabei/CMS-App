//
//  CMSAnnouncement+CoreDataProperties.swift
//  CMS App
//
//  Created by App Development on 10/5/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSAnnouncement {

    /**
    The title to display at the top of an announcement view. Because it may also be displayed in a table view cell, it is best to keep this short and concise, although no limit on characters has been imposed.
    - Warning: When saving the context, `title` may not be nil and must contain at least one character.
    */
    @NSManaged var title: String?
    
    /**
    An announcement's formatted text represents the body of the announcement. This is what will be displayed in an announcent view and can be as long as you wish. Keep in mind that if it must be long, seperating it into simple and short paragraphs may increase the chances of students at least skimming.
    - Warning: When saving the context, `formattedText` may not be nil and must contain at least one character.
    */
    @NSManaged var formattedText: String?
    
    /// A collection of attachments associated with an announcement. This takes the form of an NSSet holding CMSAttachment objects.
    @NSManaged var attachments: NSSet?

}
