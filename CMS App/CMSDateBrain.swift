//
//  ACDateBrain.swift
//  CMS Now
//
//  Created by App Development on 12/22/15.
//  Copyright © 2015 com.chambersburg. All rights reserved.
//

import Foundation

extension NSDate {
    
    func dateRetainingComponents(unitFlags unitFlags: NSCalendarUnit) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(unitFlags, fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
}

extension NSDateFormatter {
    
    func monthDay(date: NSDate) -> String {
        dateFormat = "MMMM dd"
        return stringFromDate(date)
    }
    
}