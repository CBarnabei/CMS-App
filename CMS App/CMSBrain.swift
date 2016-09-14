//
//  CMSBrain.swift
//  CMS Now
//
//  Created by App Development on 1/12/16.
//  Copyright © 2016 com.chambersburg. All rights reserved.
//

import Foundation

class CMSBrain {
    
    static func predicateForSelectedAnnouncementCategories(newDefaults: [String: AnyObject]? = nil) -> NSPredicate {
        
        var subPredicates = [NSPredicate]()
        for categoryID in CMSSettingsBrain.preferredCategories(newDefaults) {
            let subPredicate = NSPredicate(format: "category == %@", categoryID)
            subPredicates.append(subPredicate)
        }
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
        
    }
    
    static func cloudPredicateForSelectedAnnouncementCategories(newDefaults: [String: AnyObject]? = nil) -> NSPredicate {
        
        return NSPredicate(format: "Category IN %@", CMSSettingsBrain.preferredCategories(newDefaults))
        
    }
    
}