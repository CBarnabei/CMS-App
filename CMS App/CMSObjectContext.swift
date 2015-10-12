//
//  CMSObjectContext.swift
//  CMS App
//
//  Created by App Development on 10/1/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData

extension String {
    
    func isValidAttributeValue() -> Bool {
        return self.characters.count >= 1
    }
    
}

class CMSObjectContext {
    
    static func delete(object: NSManagedObject) throws {
        do {
            try CMSCoreDataBrain.deleteItem(object)
        } catch { throw error }
    }
    
    static func save() throws {
        do {
            try CMSCoreDataBrain.saveContext()
        } catch { throw error }
    }
    
}