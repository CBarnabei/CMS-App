//
//  CMSDate+CoreDataProperties.swift
//  CMS App
//
//  Created by App Development on 10/13/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSDate {

    /**
    The actual date representation of a CMSDate.
    - Warning: date may never be nil when saving the context.
    */
    @NSManaged var date: NSDate?
    
    /// A collection of announcements to be displayed for the date.
    @NSManaged var announcements: NSSet?

}
