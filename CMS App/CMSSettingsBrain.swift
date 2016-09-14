//
//  CMSSettingsBrain.swift
//  CMS App
//
//  Created by App Development on 10/20/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

let CMSSettingsChangedNotification = "CMSSettingsChangedNotification"

let CMSThemeChangedNotification = "CMSThemeChangedNotification"

class CMSSettingsBrain {
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    static let standardDefaults = NSUserDefaults.standardUserDefaults()
    
    static let categoryKeys = ["announcement_category_lunch", "announcement_category_general", "announcement_category_events", "announcement_category_birthdays", "announcement_category_sports", "announcement_category_clubs", "announcement_category_counselor", "announcement_category_principal", "announcement_category_nurse", "announcement_category_ssb", "announcement_category_graduation", "announcement_category_ptsa", "announcement_category_fcctc"]
    
    static let categoriesForKeys = ["announcement_category_lunch": "Lunch", "announcement_category_general": "General", "announcement_category_events": "Events", "announcement_category_birthdays": "Birthdays", "announcement_category_sports": "Sports", "announcement_category_clubs": "Clubs", "announcement_category_counselor": "Counselor", "announcement_category_principal": "Principal", "announcement_category_nurse": "Nurse", "announcement_category_ssb": "Student School Board", "announcement_category_graduation": "Graduation", "announcement_category_ptsa": "PTSA", "announcement_category_fcctc": "FCCTC"]

    /**
     Returns array of announcement categories the user prefers to see in their feed.
     
     - Returns: The announcement categories the user prefers to view as identifiers
    */
    static func preferredCategories(newDefaults: [String: AnyObject]? = nil) -> [String] {
        
        standardDefaults.synchronize()
        
        var chosenCategories = [String]()
        
        for (categoryID, _) in categoriesForKeys {
            if let defaults = newDefaults {
                if defaults[categoryID] as! Bool {
                    chosenCategories.append(categoryID)
                }
            } else {
                if standardDefaults.boolForKey(categoryID) {
                    chosenCategories.append(categoryID)
                }
            }
        }
        
        return chosenCategories
        
    }
    
    static func selectedThemeIndex(newDefaults: [String: AnyObject]? = nil) -> Int {
        
        standardDefaults.synchronize()
        
        return valueForKey("theme_color") as! Int
        
    }
    
    static func registerDefaults(defaults: [String: AnyObject]) {
        standardDefaults.registerDefaults(defaults)
        NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil, usingBlock: { notification in
            let appDefaults = notification.object! as! NSUserDefaults
            NSNotificationCenter.defaultCenter().postNotificationName(CMSSettingsChangedNotification, object: nil, userInfo: appDefaults.dictionaryRepresentation())
            NSNotificationCenter.defaultCenter().postNotificationName(CMSThemeChangedNotification, object: nil)
        })
    }
    
    static func valueForKey(key: String) -> AnyObject? {
        return standardDefaults.valueForKey(key)
    }
    
    static func setValueForKey(key: String, value: AnyObject) {
        standardDefaults.setValue(value, forKey: key)
        standardDefaults.synchronize()
    }
    
}