//
//  CMSAnnouncement+CoreDataProperties.swift
//  CMS Now
//
//  Created by App Development on 12/14/15.
//  Copyright © 2015 com.chambersburg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CMSAnnouncement {

    @NSManaged var category: String!
    @NSManaged var categoryIndex: Int16
    @NSManaged var endDate: NSDate
    @NSManaged var formattedText: String!
    @NSManaged var title: String!
    @NSManaged var startDate: NSDate
    @NSManaged var attachments: NSSet!
    @NSManaged var recordID: String!

}
