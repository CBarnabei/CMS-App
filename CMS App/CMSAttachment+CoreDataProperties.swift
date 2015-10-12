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

    @NSManaged var filePath: String?
    @NSManaged var title: String?
    @NSManaged var type: String?

}
