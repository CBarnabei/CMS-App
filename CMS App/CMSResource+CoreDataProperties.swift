//
//  CMSResource+CoreDataProperties.swift
//  CMS App
//
//  Created by App Development on 9/16/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSResource {

    @NSManaged var label: String?
    @NSManaged var url: String?

}
