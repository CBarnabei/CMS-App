//
//  CMSAttachment+CoreDataProperties.swift
//  CMS App
//
//  Created by App Development on 10/9/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSAttachment {

    /**
    The path to the location in storage where the actual file resides.
    - Warning: filePath may never be nil when saving the context.
    */
    @NSManaged var filePath: String?
    
    /**
    The title to be displayed alongside the attachment.
    - Warning: title may never be nil when saving the context.
    */
    @NSManaged var title: String?
    
    /**
    The type of file we are storing, represented as a `String`.
    - Warning: type may never be nil when saving the context.
    
    Cases:
    - ".pdf"
    */
    @NSManaged var type: String?

}
