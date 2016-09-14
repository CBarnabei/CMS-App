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

    /**
    The label that users will see for the resource.
    - Warning: label may never be nil when saving the context.
    */
    @NSManaged var label: String!
    
    /**
    A `String` representation of the complete website URL.
    - Warning: urlString may never be nil when saving the context.
    */
    @NSManaged var urlString: String!
    
    @NSManaged var recordID: String!

}
