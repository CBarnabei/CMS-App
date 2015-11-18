//
//  CMSSettingsBrain.swift
//  CMS App
//
//  Created by App Development on 10/20/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

enum CMSAnnouncementCategoryKey: String {
    case General = "announcement_category_general"
    case Birthdays = "announcement_category_birthdays"
    case Sports = "announcement_category_sports"
    case Clubs = "announcement_category_clubs"
    case Counselor = "announcement_category_counselor"
    case Principal = "announcement_category_principal"
    case Nurse = "announcement_category_nurse"
    case SSB = "announcement_category_ssb"
    case Graduation = "announcement_category_graduation"
    case PTSA = "announcement_category_ptsa"
    case FCCTC = "announcement_category_fcctc"
    case Other = "announcement_category_other"
}

class CMSSettingsBrain {
    
    let standardDefaults = NSUserDefaults.standardUserDefaults()
    
    let allCategories: [CMSAnnouncementCategoryKey] = [.General, .Birthdays, .Sports, .Clubs, .Principal, .Nurse, .SSB, .Graduation, .PTSA, .FCCTC, .Other]

    /**
     Returns array of announcement categories the user prefers to see in their feed.
     
     - Returns: The announcement categories the user prefers to view
    */
    func preferredCategories() -> [CMSAnnouncementCategoryKey] {
        
        standardDefaults.synchronize()
        
        var chosenCategories = allCategories
        
        for (index, category) in allCategories.enumerate() {
            let key = category.rawValue
            if !standardDefaults.boolForKey(key) {
                chosenCategories.removeAtIndex(index)
            }
        }
        
        return chosenCategories
        
    }
    
}