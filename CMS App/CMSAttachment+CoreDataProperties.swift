//
//  CMSAttachment+CoreDataProperties.swift
//  CMS App
//
//  Created by App Development on 11/10/15.
//  Copyright © 2015 com.chambersburg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSAttachment {

    @NSManaged var filePath: String?
    @NSManaged var title: String?
    @NSManaged var type: String?
    @NSManaged var announcements: NSSet?

}
